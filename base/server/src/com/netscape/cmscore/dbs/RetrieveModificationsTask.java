// --- BEGIN COPYRIGHT BLOCK ---
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; version 2 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// (C) 2007 Red Hat, Inc.
// All rights reserved.
// --- END COPYRIGHT BLOCK ---
package com.netscape.cmscore.dbs;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

import com.netscape.certsrv.base.EBaseException;

import netscape.ldap.LDAPEntry;
import netscape.ldap.LDAPSearchResults;

public class RetrieveModificationsTask implements Runnable {

    public static org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger(RetrieveModificationsTask.class);

    CertificateRepository repository;

    DBSSession session;
    LDAPSearchResults results;

    ScheduledExecutorService executorService;

    public RetrieveModificationsTask(CertificateRepository repository) {
        this.repository = repository;

        executorService = Executors.newSingleThreadScheduledExecutor(new ThreadFactory() {
            public Thread newThread(Runnable r) {
                return new Thread(r, "RetrieveModificationsTask");
            }
        });
    }

    public void start() {

        // schedule task to run immediately
        executorService.schedule(this, 0, TimeUnit.MINUTES);
    }

    public void connect() throws EBaseException {

        if (session != null) return;

        try {
            session = repository.getDBSubsystem().createSession();
            results = repository.searchForModifiedCertificateRecords(session);

        } catch (EBaseException e) {
            close(); // avoid leaks
            throw e;
        }
    }

    public void close() {

        if (session == null) return;

        // make sure the search is abandoned
        if (results != null) try { session.abandon(results); } catch (Exception e) { e.printStackTrace(); }

        // close session
        try { session.close(); } catch (Exception e) { e.printStackTrace(); }

        session = null;
    }

    public void run() {
        try {
            // make sure it's connected
            connect();

            // results.hasMoreElements() will block until next result becomes available
            // or return false if the search is abandoned or the connection is closed

            logger.debug("Waiting for next result.");
            if (results.hasMoreElements()) {
                LDAPEntry entry = results.next();

                logger.debug("Processing "+entry.getDN()+".");
                repository.getModifications(entry);
                logger.debug("Done processing "+entry.getDN()+".");

                // wait for next result immediately
                executorService.schedule(this, 0, TimeUnit.MINUTES);

            } else {
                if (executorService.isShutdown()) {
                    logger.debug("Task has been shutdown.");

                } else {
                    logger.debug("Persistence search ended.");
                    close();

                    logger.debug("Retrying in 1 minute.");
                    executorService.schedule(this, 1, TimeUnit.MINUTES);
                }
            }

        } catch (Exception e) {
            logger.warn("RetrieveModificationsTask: " + e.getMessage(), e);
            close();

            logger.warn("Retrying in 1 minute.");
            executorService.schedule(this, 1, TimeUnit.MINUTES);
        }
    }

    public void stop() {
        executorService.shutdown();
        close();
    }
}