#!/bin/sh
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/dogtag/acceptance/cli-tests/pki-user-cli
#   Description: PKI user-add CLI tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following pki cli commands needs to be tested:
#  pki-user-cli-user-add    Add users to pki KRA subsystem.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Asha Akkiangady <aakkiang@redhat.com> 
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2015 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include rhts environment
. /usr/share/beakerlib/beakerlib.sh
. /opt/rhqa_pki/rhcs-shared.sh
. /opt/rhqa_pki/pki-cert-cli-lib.sh
. /opt/rhqa_pki/env.sh

########################################################################
#create_role_users.sh should be first executed prior to pki-user-cli-user-add-kra.sh
########################################################################
run_pki-user-cli-user-add-kra_tests(){
	subsystemId=$1
	SUBSYSTEM_TYPE=$2
	MYROLE=$3
	caId=$4
	CA_HOST=$5
	prefix=$subsystemId
	# Creating Temporary Directory for pki user-kra
        rlPhaseStartSetup "pki user-kra Temporary Directory"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
        rlPhaseEnd

        # Local Variables
        get_topo_stack $MYROLE $TmpDir/topo_file
        local KRA_INST=$(cat $TmpDir/topo_file | grep MY_KRA | cut -d= -f2)
        kra_instance_created="False"
        if [ "$TOPO9" = "TRUE" ] ; then
                prefix=$KRA_INST
                kra_instance_created=$(eval echo \$${KRA_INST}_INSTANCE_CREATED_STATUS)
        elif [ "$MYROLE" = "MASTER" ] ; then
                prefix=KRA3
                kra_instance_created=$(eval echo \$${KRA_INST}_INSTANCE_CREATED_STATUS)
        else
                prefix=$MYROLE
                kra_instance_created=$(eval echo \$${KRA_INST}_INSTANCE_CREATED_STATUS)
        fi
	SUBSYSTEM_HOST=$(eval echo \$${MYROLE})
	untrusted_cert_nickname=role_user_UTCA

   if [ "$kra_instance_created" = "TRUE" ] ;  then
   	rlPhaseStartTest "pki_user_cli-configtest: pki user --help configuration test"
       		rlRun "pki user --help > $TmpDir/pki_user_cfg.out 2>&1" \
               	0 \
               "pki user --help"
        rlAssertGrep "user-find               Find users" "$TmpDir/pki_user_cfg.out"
        rlAssertGrep "user-show               Show user" "$TmpDir/pki_user_cfg.out"
        rlAssertGrep "user-add                Add user" "$TmpDir/pki_user_cfg.out"
        rlAssertGrep "user-mod                Modify user" "$TmpDir/pki_user_cfg.out"
        rlAssertGrep "user-del                Remove user" "$TmpDir/pki_user_cfg.out"
        rlAssertGrep "user-cert               User certificate management commands" "$TmpDir/pki_user_cfg.out"
        rlAssertGrep "user-membership         User membership management commands" "$TmpDir/pki_user_cfg.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-configtest: pki user-add configuration test"
        rlRun "pki user-add --help > $TmpDir/pki_user_add_cfg.out 2>&1" \
               0 \
               "pki user-add --help"
        rlAssertGrep "usage: user-add <User ID> --fullName <fullname> \[OPTIONS...\]" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--email <email>         Email" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--fullName <fullName>   Full name" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--help                  Show help options" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--password <password>   Password" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--phone <phone>         Phone" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--state <state>         State" "$TmpDir/pki_user_add_cfg.out"
        rlAssertGrep "\--type <type>           Type" "$TmpDir/pki_user_add_cfg.out"
    rlPhaseEnd

     ##### Tests to add KRA users using a user of admin group with a valid cert####
    rlPhaseStartTest "pki_user_cli_user_add-KRA-001: Add a user to KRA using KRA_adminV"
	user1=kra_agent2
	user1fullname="Test kra_agent"
        rlLog "Executing: pki -d $CERTDB_DIR \
		   -n ${prefix}_adminV \
		   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
                   -t kra \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
		    user-add --fullName=\"$user1fullname\" $user1"
        rlRun "pki -d $CERTDB_DIR -n ${prefix}_adminV -c $CERTDB_DIR_PASSWORD  -h $SUBSYSTEM_HOST -t kra -p $(eval echo \$${subsystemId}_UNSECURE_PORT)  user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-001.out"  0  "Add user $user1 to KRA_adminV"
        rlAssertGrep "Added user \"$user1\"" "$TmpDir/pki-user-add-kra-001.out"
        rlAssertGrep "User ID: $user1" "$TmpDir/pki-user-add-kra-001.out"
        rlAssertGrep "Full name: $user1fullname" "$TmpDir/pki-user-add-kra-001.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-002:maximum length of user id"
	user2=$(openssl rand -base64 30000 | strings | grep -io [[:alnum:]] | head -n 2047 | tr -d '\n')
	rlLog "user2=$user2"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test \"$user2\" > $TmpDir/pki-user-add-kra-001_1.out" \
                    0 \
                    "Added user using ${prefix}_adminV with maximum user id length"
	actual_userid_string=`cat $TmpDir/pki-user-add-kra-001_1.out | grep 'User ID:' | xargs echo`
        expected_userid_string="User ID: $user2"                       
        if [[ $actual_userid_string = $expected_userid_string ]] ; then
                rlPass "User ID: $user2 found"
        else
                rlFail "User ID: $user2 not found"
        fi
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_1.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-003:User id with # character"
	user3=abc#
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
	       	   user-add --fullName=test $user3 > $TmpDir/pki-user-add-kra-001_2.out" \
                    0 \
                    "Added user using ${prefix}_adminV, user id with # character"
        rlAssertGrep "Added user \"$user3\"" "$TmpDir/pki-user-add-kra-001_2.out"
        rlAssertGrep "User ID: $user3" "$TmpDir/pki-user-add-kra-001_2.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-004:User id with $ character"
	user4=abc$
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
		    user-add --fullName=test $user4 > $TmpDir/pki-user-add-kra-001_3.out" \
                    0 \
                    "Added user using ${prefix}_adminV, user id with $ character"
        rlAssertGrep "Added user \"$user4\"" "$TmpDir/pki-user-add-kra-001_3.out"
        rlAssertGrep "User ID: abc\\$" "$TmpDir/pki-user-add-kra-001_3.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_3.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-005:User id with @ character"
	user5=abc@
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test $user5 > $TmpDir/pki-user-add-kra-001_4.out " \
                    0 \
                    "Added user using ${prefix}_adminV, user id with @ character"
        rlAssertGrep "Added user \"$user5\"" "$TmpDir/pki-user-add-kra-001_4.out"
        rlAssertGrep "User ID: $user5" "$TmpDir/pki-user-add-kra-001_4.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_4.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-006:User id with ? character"
	user6=abc?
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test $user6 > $TmpDir/pki-user-add-kra-001_5.out " \
                    0 \
                    "Added user using ${prefix}_adminV, user id with ? character"
        rlAssertGrep "Added user \"$user6\"" "$TmpDir/pki-user-add-kra-001_5.out"
        rlAssertGrep "User ID: $user6" "$TmpDir/pki-user-add-kra-001_5.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_5.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-007:User id as 0"
	user7=0
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test $user7 > $TmpDir/pki-user-add-kra-001_6.out " \
                    0 \
                    "Added user using ${prefix}_adminV, user id 0"
        rlAssertGrep "Added user \"$user7\"" "$TmpDir/pki-user-add-kra-001_6.out"
        rlAssertGrep "User ID: $user7" "$TmpDir/pki-user-add-kra-001_6.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_6.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-008:--email with maximum length"
	email=$(openssl rand -base64 30000 | strings | grep -io [[:alnum:]] | head -n 2047 | tr -d '\n')
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --email=\"$email\" u1 > $TmpDir/pki-user-add-kra-001_7.out" \
                    0 \
                    "Added user using ${prefix}_adminV with maximum --email length"
        rlAssertGrep "Added user \"u1\"" "$TmpDir/pki-user-add-kra-001_7.out"
        rlAssertGrep "User ID: u1" "$TmpDir/pki-user-add-kra-001_7.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_7.out"
	actual_email_string=`cat $TmpDir/pki-user-add-kra-001_7.out | grep Email: | xargs echo`
        expected_email_string="Email: $email"
        if [[ $actual_email_string = $expected_email_string ]] ; then
                rlPass "Email: $email found"
        else
                rlFail "Email: $email not found"
        fi
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-009:--email with maximum length and symbols"
	specialcharacters="!?@~#*^_+$"
	email=$(openssl rand -base64 30000 | strings | grep -io [[:alnum:]] | head -n 2037 | tr -d '\n')
	email=$email$specialcharacters
	rlLog "email=$email"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --email='$email' u2 > $TmpDir/pki-user-add-kra-001_8.out" \
                    0 \
                    "Added user using ${prefix}_adminV with maximum --email length and character symbols in it"
        rlAssertGrep "Added user \"u2\"" "$TmpDir/pki-user-add-kra-001_8.out"
        rlAssertGrep "User ID: u2" "$TmpDir/pki-user-add-kra-001_8.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_8.out"
	actual_email_string=`cat $TmpDir/pki-user-add-kra-001_8.out | grep Email: | xargs echo`
        expected_email_string="Email: $email"
        if [[ $actual_email_string = $expected_email_string ]] ; then
                rlPass "Email: $email found"
        else
                rlFail "Email: $email not found"
        fi
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-010:--email with # character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --email=#  u3 > $TmpDir/pki-user-add-kra-001_9.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --email # character"
        rlAssertGrep "Added user \"u3\"" "$TmpDir/pki-user-add-kra-001_9.out"
        rlAssertGrep "User ID: u3" "$TmpDir/pki-user-add-kra-001_9.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_9.out"
        rlAssertGrep "Email: #" "$TmpDir/pki-user-add-kra-001_9.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-011:--email with * character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --email=*  u4 > $TmpDir/pki-user-add-kra-001_10.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --email * character"
        rlAssertGrep "Added user \"u4\"" "$TmpDir/pki-user-add-kra-001_10.out"
        rlAssertGrep "User ID: u4" "$TmpDir/pki-user-add-kra-001_10.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_10.out"
        rlAssertGrep "Email: *" "$TmpDir/pki-user-add-kra-001_10.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-012:--email with $ character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --email=$  u5 > $TmpDir/pki-user-add-kra-001_11.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --email $ character"
        rlAssertGrep "Added user \"u5\"" "$TmpDir/pki-user-add-kra-001_11.out"
        rlAssertGrep "User ID: u5" "$TmpDir/pki-user-add-kra-001_11.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_11.out"
        rlAssertGrep "Email: \\$" "$TmpDir/pki-user-add-kra-001_11.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-013:--email as number 0"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --email=0  u6 > $TmpDir/pki-user-add-kra-001_12.out " \
                    0 \
                    "Added user using ${prefix}_adminV with --email 0"
        rlAssertGrep "Added user \"u6\"" "$TmpDir/pki-user-add-kra-001_12.out"
        rlAssertGrep "User ID: u6" "$TmpDir/pki-user-add-kra-001_12.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_12.out"
        rlAssertGrep "Email: 0" "$TmpDir/pki-user-add-kra-001_12.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-014:--state with maximum length"
	state=$(openssl rand -base64 30000 | strings | grep -io [[:alnum:]] | head -n 2047 | tr -d '\n')
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --state=\"$state\" u7 > $TmpDir/pki-user-add-kra-001_13.out" \
                    0 \
                    "Added user using ${prefix}_adminV with maximum --state length"
        rlAssertGrep "Added user \"u7\"" "$TmpDir/pki-user-add-kra-001_13.out"
        rlAssertGrep "User ID: u7" "$TmpDir/pki-user-add-kra-001_13.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_13.out"
	actual_state_string=`cat $TmpDir/pki-user-add-kra-001_13.out | grep State: | xargs echo`
        expected_state_string="State: $state"
        if [[ $actual_state_string = $expected_state_string ]] ; then
                rlPass "State: $state found in $TmpDir/pki-user-add-kra-001_13.out"
        else
                rlFail "State: $state not found in $TmpDir/pki-user-add-kra-001_13.out"
        fi
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-015:--state with maximum length and symbols"
	specialcharacters="!?@~#*^_+$"
	state=$(openssl rand -base64 30000 | strings | grep -io [[:alnum:]] | head -n 2037 | tr -d '\n')
	state=$state$specialcharacters
	rlLog "state=$state"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
                   -t kra \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                    user-add --fullName=test --state='$state'  u8 > $TmpDir/pki-user-add-kra-001_14.out" \
                    0 \
                    "Added user using ${prefix}_adminV with maximum --state length and character symbols in it"
        rlAssertGrep "Added user \"u8\"" "$TmpDir/pki-user-add-kra-001_14.out"
        rlAssertGrep "User ID: u8" "$TmpDir/pki-user-add-kra-001_14.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_14.out"
	actual_state_string=`cat $TmpDir/pki-user-add-kra-001_14.out | grep State: | xargs echo`
        expected_state_string="State: $state"
        if [[ $actual_state_string = $expected_state_string ]] ; then
                rlPass "State: $state found in $TmpDir/pki-user-add-kra-001_14.out"
        else
                rlFail "State: $state not found in $TmpDir/pki-user-add-kra-001_14.out"
        fi
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-016:--state with # character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
                   -t kra \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                    user-add --fullName=test --state=#  u9 > $TmpDir/pki-user-add-kra-001_15.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --state # character"
        rlAssertGrep "Added user \"u9\"" "$TmpDir/pki-user-add-kra-001_15.out"
        rlAssertGrep "User ID: u9" "$TmpDir/pki-user-add-kra-001_15.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_15.out"
        rlAssertGrep "State: #" "$TmpDir/pki-user-add-kra-001_15.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-017:--state with * character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --state=*  u10 > $TmpDir/pki-user-add-kra-001_16.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --state * character"
        rlAssertGrep "Added user \"u10\"" "$TmpDir/pki-user-add-kra-001_16.out"
        rlAssertGrep "User ID: u10" "$TmpDir/pki-user-add-kra-001_16.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_16.out"
        rlAssertGrep "State: *" "$TmpDir/pki-user-add-kra-001_16.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-018:--state with $ character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --state=$  u11 > $TmpDir/pki-user-add-kra-001_17.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --state $ character"
        rlAssertGrep "Added user \"u11\"" "$TmpDir/pki-user-add-kra-001_17.out"
        rlAssertGrep "User ID: u11" "$TmpDir/pki-user-add-kra-001_17.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_17.out"
        rlAssertGrep "State: \\$" "$TmpDir/pki-user-add-kra-001_17.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-019:--state as number 0"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --state=0  u12 > $TmpDir/pki-user-add-kra-001_18.out " \
                    0 \
                    "Added user using ${prefix}_adminV with --state 0"
        rlAssertGrep "Added user \"u12\"" "$TmpDir/pki-user-add-kra-001_18.out"
        rlAssertGrep "User ID: u12" "$TmpDir/pki-user-add-kra-001_18.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_18.out"
        rlAssertGrep "State: 0" "$TmpDir/pki-user-add-kra-001_18.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-020:--phone with maximum length"
	phone=`echo $RANDOM`
        stringlength=0
        while [[ $stringlength -lt  2049 ]] ; do
                phone="$phone$RANDOM"
                stringlength=`echo $phone | wc -m`
        done
        phone=`echo $phone | cut -c1-2047`
        rlLog "phone=$phone"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --phone=\"$phone\" u13 > $TmpDir/pki-user-add-kra-001_19.out" \
                    0 \
                    "Added user using ${prefix}_adminV with maximum --phone length"
        rlAssertGrep "Added user \"u13\"" "$TmpDir/pki-user-add-kra-001_19.out"
        rlAssertGrep "User ID: u13" "$TmpDir/pki-user-add-kra-001_19.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_19.out"
        rlAssertGrep "Phone: $phone" "$TmpDir/pki-user-add-kra-001_19.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-021:--phone with maximum length and symbols"
	specialcharacters="!?@~#*^_+$"
	phone=$(openssl rand -base64 30000 | strings | grep -io [[:alnum:]] | head -n 2037 | tr -d '\n')
	phone=$state$specialcharacters
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --phone='$phone'  usr1 > $TmpDir/pki-user-add-kra-001_20.out  2>&1"\
                    255 \
                    "Should not be able to add user using ${prefix}_adminV with maximum --phone with character symbols in it"
        rlAssertGrep "ClientResponseFailure: Error status 4XX" "$TmpDir/pki-user-add-kra-001_20.out"
        rlAssertNotGrep "PKIException: LDAP error (21): error result" "$TmpDir/pki-user-add-kra-001_20.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/833#comment:1"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-022:--phone with # character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --phone=#  usr2 > $TmpDir/pki-user-add-kra-001_21.out  2>&1" \
                    255 \
                    "Should not be able to add user using ${prefix}_adminV --phone with character #"
        rlAssertGrep "ClientResponseFailure: Error status 4XX" "$TmpDir/pki-user-add-kra-001_21.out"
        rlAssertNotGrep "PKIException: LDAP error (21): error result" "$TmpDir/pki-user-add-kra-001_21.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/833#comment:1"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-023:--phone with * character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --phone=*  usr3 > $TmpDir/pki-user-add-kra-001_22.out 2>&1" \
                    255 \
                    "Should not be able to add user using ${prefix}_adminV --phone with character *"
        rlAssertGrep "ClientResponseFailure: Error status 4XX" "$TmpDir/pki-user-add-kra-001_22.out"
        rlAssertNotGrep "PKIException: LDAP error (21): error result" "$TmpDir/pki-user-add-kra-001_22.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/833#comment:1"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-024:--phone with $ character"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --phone=$  usr4 > $TmpDir/pki-user-add-kra-001_23.out 2>&1" \
                    255 \
                    "Should not be able to add user using ${prefix}_adminV --phone with character $"
        rlAssertGrep "ClientResponseFailure: Error status 4XX" "$TmpDir/pki-user-add-kra-001_23.out"
        rlAssertNotGrep "PKIException: LDAP error (21): error result" "$TmpDir/pki-user-add-kra-001_23.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/833#comment:1"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-025:--phone as negative number -1230"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --phone=-1230  u14 > $TmpDir/pki-user-add-kra-001_24.out " \
                    0 \
                    "Added user using ${prefix}_adminV with --phone -1230"
        rlAssertGrep "Added user \"u14\"" "$TmpDir/pki-user-add-kra-001_24.out"
        rlAssertGrep "User ID: u14" "$TmpDir/pki-user-add-kra-001_24.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_24.out"
        rlAssertGrep "Phone: -1230" "$TmpDir/pki-user-add-kra-001_24.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-026:--type as Auditors"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=Auditors u15 > $TmpDir/pki-user-add-kra-001_25.out" \
                    0 \
                    "Added user using ${prefix}_adminV with  --type Auditors"
        rlAssertGrep "Added user \"u15\"" "$TmpDir/pki-user-add-kra-001_25.out"
        rlAssertGrep "User ID: u15" "$TmpDir/pki-user-add-kra-001_25.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_25.out"
        rlAssertGrep "Type: Auditors" "$TmpDir/pki-user-add-kra-001_25.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-027:--type Certificate Manager Agents"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=\"Certificate Manager Agents\" u16 > $TmpDir/pki-user-add-kra-001_26.out" \
                    0 \
                    "Added user using ${prefix}_adminV  --type Certificate Manager Agents"
        rlAssertGrep "Added user \"u16\"" "$TmpDir/pki-user-add-kra-001_26.out"
        rlAssertGrep "User ID: u16" "$TmpDir/pki-user-add-kra-001_26.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_26.out"
        rlAssertGrep "Type: Certificate Manager Agents" "$TmpDir/pki-user-add-kra-001_26.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-028:--type Registration Manager Agents"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=\"Registration Manager Agents\"  u17 > $TmpDir/pki-user-add-kra-001_27.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --type Registration Manager Agents"
        rlAssertGrep "Added user \"u17\"" "$TmpDir/pki-user-add-kra-001_27.out"
        rlAssertGrep "User ID: u17" "$TmpDir/pki-user-add-kra-001_27.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_27.out"
        rlAssertGrep "Type: Registration Manager Agents" "$TmpDir/pki-user-add-kra-001_27.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-029:--type Subsytem Group"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=\"Subsytem Group\"  u18 > $TmpDir/pki-user-add-kra-001_28.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --type Subsytem Group"
        rlAssertGrep "Added user \"u18\"" "$TmpDir/pki-user-add-kra-001_28.out"
        rlAssertGrep "User ID: u18" "$TmpDir/pki-user-add-kra-001_28.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_28.out"
        rlAssertGrep "Type: Subsytem Group" "$TmpDir/pki-user-add-kra-001_28.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-030:--type Security Domain Administrators"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=\"Security Domain Administrators\" u19 > $TmpDir/pki-user-add-kra-001_29.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --type Security Domain Administrators"
        rlAssertGrep "Added user \"u19\"" "$TmpDir/pki-user-add-kra-001_29.out"
        rlAssertGrep "User ID: u19" "$TmpDir/pki-user-add-kra-001_29.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_29.out"
        rlAssertGrep "Type: Security Domain Administrators" "$TmpDir/pki-user-add-kra-001_29.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-031:--type ClonedSubsystems"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=ClonedSubsystems u20 > $TmpDir/pki-user-add-kra-001_30.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --type ClonedSubsystems"
        rlAssertGrep "Added user \"u20\"" "$TmpDir/pki-user-add-kra-001_30.out"
        rlAssertGrep "User ID: u20" "$TmpDir/pki-user-add-kra-001_30.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_30.out"
        rlAssertGrep "Type: ClonedSubsystems" "$TmpDir/pki-user-add-kra-001_30.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-032:--type Trusted Managers"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=\"Trusted Managers\" u21 > $TmpDir/pki-user-add-kra-001_31.out" \
                    0 \
                    "Added user using ${prefix}_adminV with --type Trusted Managers"
        rlAssertGrep "Added user \"u21\"" "$TmpDir/pki-user-add-kra-001_31.out"
        rlAssertGrep "User ID: u21" "$TmpDir/pki-user-add-kra-001_31.out"
        rlAssertGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_31.out"
        rlAssertGrep "Type: Trusted Managers" "$TmpDir/pki-user-add-kra-001_31.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-033:--type Dummy Group"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type=\"Dummy Group\" u25 > $TmpDir/pki-user-add-kra-001_33.out 2>&1 "  \
                    1,255 \
                    "Adding user using ${prefix}_adminV with --type Dummy Group"
        rlAssertNotGrep "Added user \"u25\"" "$TmpDir/pki-user-add-kra-001_33.out"
        rlAssertNotGrep "User ID: u25" "$TmpDir/pki-user-add-kra-001_33.out"
        rlAssertNotGrep "Full name: test" "$TmpDir/pki-user-add-kra-001_33.out"
        rlAssertNotGrep "Type: Dummy Group" "$TmpDir/pki-user-add-kra-001_33.out"
        rlAssertGrep "ClientResponseFailure: Error status 4XX" "$TmpDir/pki-user-add-kra-001_33.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/704"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-034: Add a duplicate user to KRA"
	command="pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"New user\" $user1 > $TmpDir/pki-user-add-kra-002.out 2>&1 "

        expmsg="ConflictingOperationException: Entry already exists."
        rlRun "$command" 255 "Add duplicate user"
        rlAssertGrep "$expmsg" "$TmpDir/pki-user-add-kra-002.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-036:  Add a user -- missing required option user id"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" > $TmpDir/pki-user-add-kra-004.out" \
                    255 \
                    "Add user -- missing required option user id"
        rlAssertGrep "usage: user-add <User ID> --fullName <fullname> \[OPTIONS...\]" "$TmpDir/pki-user-add-kra-004.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-037:  Add a user -- missing required option --fullName"
        command="pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add $user1 > $TmpDir/pki-user-add-kra-005.out 2>&1"
        errmsg="Error: Missing required option: fullName"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Add a user -- missing required option --fullName"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-038:  Add a user -- all options provided"
        email="kra_agent2@myemail.com"
        user_password="agent2Password"
        phone="1234567890"
        state="NC"
        type="Administrators"
        rlLog "Executing: pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\"  \
                    --email $email \
                    --password $user_password \
                    --phone $phone \
                    --state $state \
                    --type $type \
                     u23"

        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\"  \
		    --email $email \
		    --password $user_password \
		    --phone $phone \
		    --state $state \
		    --type $type \
		     u23 >  $TmpDir/pki-user-add-kra-006_1.out" \
                    0 \
                    "Add user u23 to KRA -- all options provided"
        rlAssertGrep "Added user \"u23\"" "$TmpDir/pki-user-add-kra-006_1.out"
        rlAssertGrep "User ID: u23" "$TmpDir/pki-user-add-kra-006_1.out"
        rlAssertGrep "Full name: $user1fullname" "$TmpDir/pki-user-add-kra-006_1.out"
        rlAssertGrep "Email: $email" "$TmpDir/pki-user-add-kra-006_1.out"
        rlAssertGrep "Phone: $phone" "$TmpDir/pki-user-add-kra-006_1.out"
        rlAssertGrep "Type: $type" "$TmpDir/pki-user-add-kra-006_1.out"
        rlAssertGrep "State: $state" "$TmpDir/pki-user-add-kra-006_1.out"
   rlPhaseEnd

   rlPhaseStartTest "pki_user_cli_user_add-KRA-039:  Add user to multiple groups"
       user=u24
       userfullname="Multiple Group User"
       email="multiplegroup@myemail.com"
       user_password="admin2Password"
       phone="1234567890"
       state="NC"
       rlRun "pki -d $CERTDB_DIR \
                  -n ${prefix}_adminV \
                  -c $CERTDB_DIR_PASSWORD \
 		  -h $SUBSYSTEM_HOST \
 		  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                  -t kra \
                   user-add --fullName=\"$userfullname\"  \
                   --email $email \
                   --password $user_password \
                   --phone $phone \
                   --state $state \
                    $user > $TmpDir/pki-user-add-kra-006.out " \
                   0 \
                   "Add user $user using ${prefix}_adminV"
       rlAssertGrep "Added user \"u24\"" "$TmpDir/pki-user-add-kra-006.out"
       rlAssertGrep "User ID: u24" "$TmpDir/pki-user-add-kra-006.out"
       rlAssertGrep "Full name: $userfullname" "$TmpDir/pki-user-add-kra-006.out"
       rlAssertGrep "Email: $email" "$TmpDir/pki-user-add-kra-006.out"
       rlAssertGrep "Phone: $phone" "$TmpDir/pki-user-add-kra-006.out"
       rlAssertGrep "State: $state" "$TmpDir/pki-user-add-kra-006.out"
       rlRun "pki -d $CERTDB_DIR \
                  -n ${prefix}_adminV \
                  -c $CERTDB_DIR_PASSWORD \
 		  -h $SUBSYSTEM_HOST \
 		  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                  -t kra \
                   group-member-add Administrators $user > $TmpDir/pki-user-add-kra-007_1.out"  \
                   0 \
                   "Add user $user to Administrators group"

       rlAssertGrep "Added group member \"$user\"" "$TmpDir/pki-user-add-kra-007_1.out"
       rlAssertGrep "User: $user" "$TmpDir/pki-user-add-kra-007_1.out"

       rlRun "pki -d $CERTDB_DIR \
                  -n ${prefix}_adminV \
                  -c $CERTDB_DIR_PASSWORD \
 		  -h $SUBSYSTEM_HOST \
 		  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                  -t kra \
                   group-member-find Administrators > $TmpDir/pki-user-add-kra-007.out" \
                   0 \
                   "Show pki group-member-find Administrators"
       rlRun "pki -d $CERTDB_DIR \
                  -n ${prefix}_adminV \
                  -c $CERTDB_DIR_PASSWORD \
 		  -h $SUBSYSTEM_HOST \
 		  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                  -t kra \
                   group-member-add \"Data Recovery Manager Agents\"  $user > $TmpDir/pki-user-add-kra-007_1_1.out"  \
                   0 \
                   "Add user $user to Data Recovery Manager Agents group"

       rlAssertGrep "Added group member \"$user\"" "$TmpDir/pki-user-add-kra-007_1_1.out"
       rlAssertGrep "User: $user" "$TmpDir/pki-user-add-kra-007_1_1.out"

       rlRun "pki -d $CERTDB_DIR \
                  -n ${prefix}_adminV \
                  -c $CERTDB_DIR_PASSWORD \
 		  -h $SUBSYSTEM_HOST \
 		  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                  -t kra \
                   group-member-find \"Data Recovery Manager Agents\"  > $TmpDir/pki-user-add-kra-007_2.out" \
                   0 \
                   "Show pki group-member-find Data Recovery Manager Agents"

       rlAssertGrep "User: $user" "$TmpDir/pki-user-add-kra-007_2.out"
   rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-040: Add user with --password less than 8 characters"
        userpw="pass"
        expmsg="PKIException: The password must be at least 8 characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
		   -t kra \
                    user-add --fullName=\"$user1fullname\" --password=$userpw $user1 > $TmpDir/pki-user-add-kra-008.out 2>&1" \
                    255 \
                    "Add a user --must be at least 8 characters --password"
        rlAssertGrep "$expmsg" "$TmpDir/pki-user-add-kra-008.out"
    rlPhaseEnd

        ##### Tests to add users using revoked cert#####
    rlPhaseStartTest "pki_user_cli_user_add-KRA-041: Should not be able to add user using a revoked cert KRA_adminR"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminR \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-revoke-adminR-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a user having revoked cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-user-add-kra-revoke-adminR-002.out"
	rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1134"
        rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1182"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-042: Should not be able to add user using a agent with revoked cert KRA_agentR"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_agentR \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-revoke-agentR-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a user having revoked cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-user-add-kra-revoke-agentR-002.out"
	rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1134"
        rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1182"
    rlPhaseEnd


        ##### Tests to add users using an agent user#####
    rlPhaseStartTest "pki_user_cli_user_add-KRA-043: Should not be able to add user using a valid agent KRA_agentV user"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_agentV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-agentV-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a agent cert"
        rlAssertGrep "ForbiddenException: Authorization Error" "$TmpDir/pki-user-add-kra-agentV-002.out"
    rlPhaseEnd

	 ##### Tests to add users using CA_agentUTCA user's certificate will be issued by an untrusted CA #####
    rlPhaseStartTest "pki_user_cli_user_add-KRA-044: Should not be able to add user using a KRA_agentUTCA user"
        rlRun "pki -d $UNTRUSTED_CERT_DB_LOCATION \
                   -n $untrusted_cert_nickname \
                   -c $UNTRUSTED_CERT_DB_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-agentUTCA-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a agent cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-user-add-kra-agentUTCA-002.out"
    rlPhaseEnd

    ##### Tests to add users using expired cert#####
    rlPhaseStartTest "pki_user_cli_user_add-KRA-045: Should not be able to add user using admin user with expired cert KRA_adminE"
	#Set datetime 2 days ahead
        rlRun "date --set='+2 days'" 0 "Set System date 2 days ahead"
        rlRun "date"
	rlLog "Executing: pki -d $CERTDB_DIR \
                   -n ${prefix}_adminE \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminE \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-adminE-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using an expired admin cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-user-add-kra-adminE-002.out"
        rlAssertNotGrep "ProcessingException: Unable to invoke request" "$TmpDir/pki-user-add-kra-adminE-002.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/962"
	rlRun "date --set='2 days ago'" 0 "Set System back to the present day"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-046: Should not be able to add user using KRA_agentE cert"
	#Set datetime 2 days ahead
        rlRun "date --set='+2 days'" 0 "Set System date 2 days ahead"
        rlRun "date"
        rlLog "Executing: pki -d $CERTDB_DIR \
                   -n ${prefix}_agentE \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_agentE \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-agentE-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a agent cert"
        rlAssertGrep "ClientResponseFailure: Error status 401 Unauthorized returned" "$TmpDir/pki-user-add-kra-agentE-002.out"
        rlAssertNotGrep "ProcessingException: Unable to invoke request" "$TmpDir/pki-user-add-kra-agentE-002.out"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/962"
	rlRun "date --set='2 days ago'" 0 "Set System back to the present day"
    rlPhaseEnd

	##### Tests to add users using audit users#####
    rlPhaseStartTest "pki_user_cli_user_add-KRA-047: Should not be able to add user using a KRA_auditV"
	rlLog "Executing: pki -d $CERTDB_DIR \
                   -n ${prefix}_auditV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_auditV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-auditV-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a audit cert"
        rlAssertGrep "ForbiddenException: Authorization Error" "$TmpDir/pki-user-add-kra-auditV-002.out"
    rlPhaseEnd


	##### Tests to add users using operator user###
    rlPhaseStartTest "pki_user_cli_user_add-KRA-048: Should not be able to add user using a KRA_operatorV"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_operatorV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-operatorV-002.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a operator cert"
        rlAssertGrep "ForbiddenException: Authorization Error" "$TmpDir/pki-user-add-kra-operatorV-002.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-049: Should not be able to add user using a cert created from a untrusted KRA KRA_adminUTCA"
	rlLog "Executing: pki -d $UNTRUSTED_CERT_DB_LOCATION \
                   -n $untrusted_cert_nickname \
                   -c $UNTRUSTED_CERT_DB_PASSWORD  \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1"
	rlRun "pki -d $UNTRUSTED_CERT_DB_LOCATION \
                   -n $untrusted_cert_nickname \
                   -c $UNTRUSTED_CERT_DB_PASSWORD \
		   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=\"$user1fullname\" $user1 > $TmpDir/pki-user-add-kra-adminUTCA-003.out 2>&1" \
                    255 \
                    "Should not be able to add user $user1 using a untrusted cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-user-add-kra-adminUTCA-003.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-050: user id length exceeds maximum limit defined in the schema"
	user_length_exceed_max=$(openssl rand -base64 80000 | strings | grep -io [[:alnum:]] | head -n 10000 | tr -d '\n')
	rlLog "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test \"$user_length_exceed_max\""
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test \"$user_length_exceed_max\" > $TmpDir/pki-user-add-kra-001_50.out 2>&1" \
                    255 \
                    "Adding user using ${prefix}_adminV with user id length exceed maximum defined in ldap schema"
        rlAssertNotGrep "ClientResponseFailure: Error status 500 Internal Server Error returned" "$TmpDir/pki-user-add-kra-001_50.out"
        rlAssertGrep "ProcessingException: Unable to invoke request" "$TmpDir/pki-user-add-kra-001_50.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-051: fullname with i18n characters"
	rlLog "user-add fullname ??rjan ??ke with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName='??rjan ??ke' u26 > $TmpDir/pki-user-add-kra-001_51.out 2>&1" \
                    0 \
                    "Adding u26 with full name ??rjan ??ke"
	rlAssertGrep "Added user \"u26\"" "$TmpDir/pki-user-add-kra-001_51.out"
        rlAssertGrep "User ID: u26" "$TmpDir/pki-user-add-kra-001_51.out"
        rlAssertGrep "Full name: ??rjan ??ke" "$TmpDir/pki-user-add-kra-001_51.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-052: fullname with i18n characters"
	rlLog "user-add fullname ??ric T??ko with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName='??ric T??ko' u27 > $TmpDir/pki-user-add-kra-001_52.out 2>&1" \
                    0 \
                    "Adding u27 with full ??ric T??ko"
        rlAssertGrep "Added user \"u27\"" "$TmpDir/pki-user-add-kra-001_52.out"
        rlAssertGrep "User ID: u27" "$TmpDir/pki-user-add-kra-001_52.out"
        rlAssertGrep "Full name: ??ric T??ko" "$TmpDir/pki-user-add-kra-001_52.out"
    rlPhaseEnd 

    rlPhaseStartTest "pki_user_cli_user_add-KRA-053: fullname with i18n characters"
	rlLog "user-add fullname ????nentwintig dvide??imt with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName='????nentwintig dvide??imt' u28 > $TmpDir/pki-user-add-kra-001_53.out 2>&1" \
                    0 \
                    "Adding fullname ????nentwintig dvide??imt with i18n characters"
        rlAssertGrep "Added user \"u28\"" "$TmpDir/pki-user-add-kra-001_53.out"
        rlAssertGrep "Full name: ????nentwintig dvide??imt" "$TmpDir/pki-user-add-kra-001_53.out"
        rlAssertGrep "User ID: u28" "$TmpDir/pki-user-add-kra-001_53.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
		   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u28 > $TmpDir/pki-user-add-kra-001_53_2.out 2>&1" \
                    0 \
                    "Show user u28 with fullname ????nentwintig dvide??imt in i18n characters"
        rlAssertGrep "User \"u28\"" "$TmpDir/pki-user-add-kra-001_53_2.out"
        rlAssertGrep "Full name: ????nentwintig dvide??imt" "$TmpDir/pki-user-add-kra-001_53_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-054: fullname with i18n characters"
	rlLog "user-add fullname kaksk??mmend ??ks with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName='kaksk??mmend ??ks' u29 > $TmpDir/pki-user-add-kra-001_54.out 2>&1" \
                    0 \
                    "Adding fillname kaksk??mmend ??ks with i18n characters"
        rlAssertGrep "Added user \"u29\"" "$TmpDir/pki-user-add-kra-001_54.out"
        rlAssertGrep "Full name: kaksk??mmend ??ks" "$TmpDir/pki-user-add-kra-001_54.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u29 > $TmpDir/pki-user-add-kra-001_54_2.out" \
                    0 \
                    "Show user u29 with fullname kaksk??mmend ??ks in i18n characters"
        rlAssertGrep "User \"u29\"" "$TmpDir/pki-user-add-kra-001_54_2.out"
        rlAssertGrep "Full name: kaksk??mmend ??ks" "$TmpDir/pki-user-add-kra-001_54_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-055: fullname with i18n characters"
	rlLog "user-add fullname ???????????????? ???????? ???????????????? with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName='???????????????? ???????? ????????????????' u30 > $TmpDir/pki-user-add-kra-001_55.out 2>&1" \
                    0 \
                    "Adding fillname ???????????????? ???????? ???????????????? with i18n characters"
        rlAssertGrep "Added user \"u30\"" "$TmpDir/pki-user-add-kra-001_55.out"
        rlAssertGrep "Full name: ???????????????? ???????? ????????????????" "$TmpDir/pki-user-add-kra-001_55.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u30 > $TmpDir/pki-user-add-kra-001_55_2.out" \
                    0 \
                    "Show user u30 with fullname ???????????????? ???????? ???????????????? in i18n characters"
        rlAssertGrep "User \"u30\"" "$TmpDir/pki-user-add-kra-001_55_2.out"
        rlAssertGrep "Full name: ???????????????? ???????? ????????????????" "$TmpDir/pki-user-add-kra-001_55_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-056: user id with i18n characters"
	rlLog "user-add userid ??rjan??ke with i18n characters"
        rlLog "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test '??rjan??ke'"
        command="pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test '??rjan??ke'"
	errmsg="IncorrectUserIdException"
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Adding uid ??rjan??ke with i18n characters"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/860"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-057: userid with i18n characters"
	rlLog "user-add userid ??ricT??ko with i18n characters"
        rlLog "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test '??ricT??ko'"
        command="pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test '??ricT??ko'"
	errmsg="IncorrectUserIdException"
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0  "Adding user id ??ricT??ko with i18n characters"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/860"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-058: email address with i18n characters"
	rlLog "user-add email address negyvenkett??@qetestsdomain.com with i18n characters"
	command="pki -d $CERTDB_DIR -n ${prefix}_adminV -c $CERTDB_DIR_PASSWORD -h $SUBSYSTEM_HOST -p $(eval echo \$${subsystemId}_UNSECURE_PORT) -t kra user-add --fullName=test  --email='negyvenkett??@qetestsdomain.com' u31"
        rlLog "Executing $command"
        errmsg="ProcessingException: Unable to invoke request"
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Adding email negyvenkett??@qetestsdomain.com with i18n characters"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/860"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-059: email address with i18n characters"
	rlLog "user-add email address ??etrdesmitdivi@qetestsdomain.com with i18n characters"
        command="pki -d $CERTDB_DIR -n ${prefix}_adminV  -c $CERTDB_DIR_PASSWORD -h $SUBSYSTEM_HOST -p $(eval echo \$${subsystemId}_UNSECURE_PORT) -t kra user-add --fullName=test --email='??etrdesmitdivi@qetestsdomain.com' u32"
        rlLog "Executing $command"
        errmsg="IncorrectPasswordException: Incorrect NSS database password."
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Adding email ??etrdesmitdivi@qetestsdomain.com with i18n characters"
        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/860"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-060: password with i18n characters"
	rlLog "user-add password ??imtaskolmk??mmend with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --password='??imtaskolmk??mmend' u31 > $TmpDir/pki-user-add-kra-001_60.out 2>&1" \
                    0 \
                    "Adding password ??imtaskolmk??mmend with i18n characters"
        rlAssertGrep "Added user \"u31\"" "$TmpDir/pki-user-add-kra-001_60.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u31 > $TmpDir/pki-user-add-kra-001_60_2.out" \
                    0 \
                    "Show user u31 with password ??imtaskolmk??mmend in i18n characters"
        rlAssertGrep "User \"u31\"" "$TmpDir/pki-user-add-kra-001_60_2.out"
    rlPhaseEnd 

    rlPhaseStartTest "pki_user_cli_user_add-KRA-061: password with i18n characters"
	rlLog "user-add password ?????????????????????????????? with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --password='??????????????????????????????' u32 > $TmpDir/pki-user-add-kra-001_61.out 2>&1" \
                    0 \
                    "Adding password ?????????????????????????????? with i18n characters"
        rlAssertGrep "Added user \"u32\"" "$TmpDir/pki-user-add-kra-001_61.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u32 > $TmpDir/pki-user-add-kra-001_61_2.out" \
                    0 \
                    "Show user u32 with password ?????????????????????????????? in i18n characters"
        rlAssertGrep "User \"u32\"" "$TmpDir/pki-user-add-kra-001_61_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-062: type with i18n characters"
	rlLog "user-add type tjugo-tv??hetvenh??t with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type='tjugo-tv??hetvenh??t' u33 > $TmpDir/pki-user-add-kra-001_62.out 2>&1" \
                    0 \
                    "Adding type tjugo-tv??hetvenh??t with i18n characters"
        rlAssertGrep "Added user \"u33\"" "$TmpDir/pki-user-add-kra-001_62.out"
	rlAssertGrep "Type: tjugo-tv??hetvenh??t" "$TmpDir/pki-user-add-kra-001_62.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u33 > $TmpDir/pki-user-add-kra-001_62_2.out" \
                    0 \
                    "Show user u33 with type tjugo-tv??hetvenh??t in i18n characters"
        rlAssertGrep "User \"u33\"" "$TmpDir/pki-user-add-kra-001_62_2.out"
	rlAssertGrep "Type: tjugo-tv??hetvenh??t" "$TmpDir/pki-user-add-kra-001_62_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-063: type with i18n characters"
	rlLog "user-add type ??i?????????????????????????? with i18n characters"
	rlLog "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
                   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type='??i??????????????????????????' u34"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --type='??i??????????????????????????' u34 > $TmpDir/pki-user-add-kra-001_63.out 2>&1" \
                    0 \
                    "Adding type ??i?????????????????????????? with i18n characters"
        rlAssertGrep "Added user \"u34\"" "$TmpDir/pki-user-add-kra-001_63.out"
        rlAssertGrep "Type: ??i??????????????????????????" "$TmpDir/pki-user-add-kra-001_63.out"
	rlLog "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
                   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u34"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u34 > $TmpDir/pki-user-add-kra-001_63_2.out" \
                    0 \
                    "Show user u34 with type ??i?????????????????????????? in i18n characters"
        rlAssertGrep "User \"u34\"" "$TmpDir/pki-user-add-kra-001_63_2.out"
        rlAssertGrep "Type: ??i??????????????????????????" "$TmpDir/pki-user-add-kra-001_63_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-064: state with i18n characters"
	rlLog "user-add state ???? with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --state='????' u35 > $TmpDir/pki-user-add-kra-001_64.out 2>&1" \
                    0 \
                    "Adding state '????' with i18n characters"
        rlAssertGrep "Added user \"u35\"" "$TmpDir/pki-user-add-kra-001_64.out"
        rlAssertGrep "State: ????" "$TmpDir/pki-user-add-kra-001_64.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u35 > $TmpDir/pki-user-add-kra-001_64_2.out" \
                    0 \
                    "Show user u35 with state ???? in i18n characters"
        rlAssertGrep "User \"u35\"" "$TmpDir/pki-user-add-kra-001_64_2.out"
        rlAssertGrep "State: ????" "$TmpDir/pki-user-add-kra-001_64_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-065: state with i18n characters"
	rlLog "user-add state ???? with i18n characters"

        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test --state='????' u36 > $TmpDir/pki-user-add-kra-001_65.out 2>&1" \
                    0 \
                    "Adding state '????' with i18n characters"
        rlAssertGrep "Added user \"u36\"" "$TmpDir/pki-user-add-kra-001_65.out"
        rlAssertGrep "State: ????" "$TmpDir/pki-user-add-kra-001_65.out"
        rlRun "pki -d $CERTDB_DIR \
                   -n ${prefix}_adminV \
                   -c $CERTDB_DIR_PASSWORD \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-show u36 > $TmpDir/pki-user-add-kra-001_65_2.out" \
                    0 \
                    "Show user u36 with state ???? in i18n characters"
        rlAssertGrep "User \"u36\"" "$TmpDir/pki-user-add-kra-001_65_2.out"
        rlAssertGrep "State: ????" "$TmpDir/pki-user-add-kra-001_65_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-066: Should not be able to add user using a user cert"
        #Create a user cert
        local TEMP_NSS_DB="$TmpDir/nssdb"
        local ret_reqstatus
        local ret_requestid
        local valid_serialNumber
        local temp_out="$TmpDir/usercert-show.out"
	rlLog "create_cert_request $TEMP_NSS_DB Password pkcs10 rsa 2048 \"pki User1\" \"pkiUser1\" \
                \"pkiuser1@example.org\" \"Engineering\" \"Example.Inc\" \"US\" \"--\" \"ret_reqstatus\" \"ret_requestid\" \"$CA_HOST\" \"$(eval echo \$${caId}_UNSECURE_PORT)\" " 0 "Generating  pkcs10 Certificate Request"
        rlRun "create_cert_request $TEMP_NSS_DB Password pkcs10 rsa 2048 \"pki User1\" \"pkiUser1\" \
                \"pkiuser1@example.org\" \"Engineering\" \"Example.Inc\" \"US\" \"--\" \"ret_reqstatus\" \"ret_requestid\" \"$CA_HOST\" \"$(eval echo \$${caId}_UNSECURE_PORT)\" " 0 "Generating  pkcs10 Certificate Request"
        rlLog "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"${caId}_agentV\" -h $CA_HOST -p $(eval echo \$${caId}_UNSECURE_PORT) ca-cert-request-review $ret_requestid \
                --action approve 1"
        rlRun "pki -d $CERTDB_DIR -c $CERTDB_DIR_PASSWORD -n \"${caId}_agentV\" -h $CA_HOST -p $(eval echo \$${caId}_UNSECURE_PORT) ca-cert-request-review $ret_requestid \
                --action approve 1> $TmpDir/pki-approve-out" 0 "Approve Certificate request"
        rlAssertGrep "Approved certificate request $ret_requestid" "$TmpDir/pki-approve-out"
        rlLog "pki -h $CA_HOST -p $(eval echo \$${caId}_UNSECURE_PORT) cert-request-show $ret_requestid | grep \"Certificate ID\" | sed 's/ //g' | cut -d: -f2)"
        rlRun "pki -h $CA_HOST -p $(eval echo \$${caId}_UNSECURE_PORT) cert-request-show $ret_requestid > $TmpDir/usercert-show1.out"
        valid_serialNumber=`cat $TmpDir/usercert-show1.out | grep 'Certificate ID' | sed 's/ //g' | cut -d: -f2`
        rlLog "valid_serialNumber=$valid_serialNumber"
        #Import user certs to $TEMP_NSS_DB
        rlRun "pki -h $CA_HOST -p $(eval echo \$${caId}_UNSECURE_PORT) cert-show $valid_serialNumber --encoded > $temp_out" 0 "command pki cert-show $valid_serialNumber --encoded"
        rlRun "certutil -d $TEMP_NSS_DB -A -n pkiUser1 -i $temp_out  -t \"u,u,u\""
        local expfile="$TmpDir/expfile_pkiuser1.out"
        rlLog "Executing: pki -d $TEMP_NSS_DB \
                   -n pkiUser1 \
                   -c Password \
 		   -h $SUBSYSTEM_HOST \
 		   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   -t kra \
                    user-add --fullName=test_user u39"
        echo "spawn -noecho pki -d $TEMP_NSS_DB -n pkiUser1 -c Password -h $SUBSYSTEM_HOST -p $(eval echo \$${subsystemId}_UNSECURE_PORT) user-add --fullName=test_user u39" > $expfile
        echo "expect \"WARNING: UNTRUSTED ISSUER encountered on '$(eval echo \$${subsystemId}_SSL_SERVER_CERT_SUBJECT_NAME)' indicates a non-trusted CA cert '$(eval echo \$$subsystemId{}_SIGNING_CERT_SUBJECT_NAME)'
Import CA certificate (Y/n)? \"" >> $expfile
        echo "send -- \"Y\r\"" >> $expfile
        echo "expect \"CA server URL \[http://$HOSTNAME:8080/ca\]: \"" >> $expfile
        echo "send -- \"http://$HOSTNAME:$(eval echo \$${caId}_UNSECURE_PORT)/ca\r\"" >> $expfile
        echo "expect eof" >> $expfile
	echo "catch wait result" >> $expfile
        echo "exit [lindex \$result 3]" >> $expfile
        rlRun "/usr/bin/expect -f $expfile >  $TmpDir/pki-user-add-kra-pkiUser1-002.out 2>&1" 255 "Should not be able to add users using a user cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-user-add-kra-pkiUser1-002.out"
    rlPhaseEnd
 
    rlPhaseStartTest "pki_user_cli_user_add-KRA-067: Should not be able to add user using Normal user credential"
	local pki_user="idm1_user_1"
        local pki_user_fullName="Idm1 User 1"
        local pki_pwd="Secret123"
        rlLog "Create user $pki_user"
        rlRun "pki -d $CERTDB_DIR \
                -n \"${prefix}_adminV\" \
                -c $CERTDB_DIR_PASSWORD -h $SUBSYSTEM_HOST -p $(eval echo \$${subsystemId}_UNSECURE_PORT)  \
                -t kra \
                user-add $pki_user \
                --fullName \"$pki_user_fullName\" \
                --password $pki_pwd" 0 "Create $pki_user User"	
	local TEMP_NSS_DB="$TmpDir/nssdb"
	rlLog "Executing: pki -d $CERTDB_DIR \
                   -c $CERTDB_DIR_PASSWORD \
                   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
		   -u $pki_user \
		   -w $pki_pwd \
                   -t kra \
                    user-add --fullName=test_user u39"
	command="pki -d $CERTDB_DIR \
                   -c $CERTDB_DIR_PASSWORD \
                   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
		   -u $pki_user \
		   -w $pki_pwd \
                   -t kra \
                    user-add --fullName=test_user u39"
	errmsg="ForbiddenException: Authentication method not allowed."
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0  "Adding user using Normal user credential"
    rlPhaseEnd

    rlPhaseStartTest "pki_user_cli_user_add-KRA-068: Should not be able to add user using invalid user credential"
	local invalid_pki_user=test1
        local invalid_pki_user_pwd=Secret123
        rlLog "Executing: pki -d $CERTDB_DIR \
                   -c $CERTDB_DIR_PASSWORD \
                   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
		   -u $invalid_pki_user \
		   -w $invalid_pki_user_pwd \
                   -t kra \
                    user-add --fullName=test_user u39"
        command="pki -d $CERTDB_DIR \
                   -c $CERTDB_DIR_PASSWORD \
                   -h $SUBSYSTEM_HOST \
                   -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
		   -u $invalid_pki_user \
		   -w $invalid_pki_user_pwd \
                   -t kra \
                    user-add --fullName=test_user u39"
        errmsg="PKIException: Unauthorized"
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0  "Adding user using Normal user credential"
    rlPhaseEnd

    rlPhaseStartCleanup "pki_user_cli_user_cleanup: Deleting users"

        #===Deleting users created using ${prefix}_adminV cert===#
        i=1
	while [ $i -lt 22 ] ; do
               rlRun "pki -d $CERTDB_DIR \
                          -n ${prefix}_adminV \
                          -c $CERTDB_DIR_PASSWORD \
                          -h $SUBSYSTEM_HOST \
                          -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                          -t kra \
                           user-del  u$i > $TmpDir/pki-user-del-kra-user-00$i.out" \
                           0 \
                           "Deleted user  u$i"
                rlAssertGrep "Deleted user \"u$i\"" "$TmpDir/pki-user-del-kra-user-00$i.out"
                let i=$i+1
        done
        i=23
        while [ $i -lt 37 ] ; do
               rlRun "pki -d $CERTDB_DIR \
                          -n ${prefix}_adminV \
                          -c $CERTDB_DIR_PASSWORD \
 		          -h $SUBSYSTEM_HOST \
 		    	  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   	  -t kra \
                           user-del  u$i > $TmpDir/pki-user-del-kra-user-00$i.out" \
                           0 \
                           "Deleted user  u$i"
                rlAssertGrep "Deleted user \"u$i\"" "$TmpDir/pki-user-del-kra-user-00$i.out"
                let i=$i+1
        done
        #===Deleting users(symbols) created using ${prefix}_adminV cert===#
        j=1
        while [ $j -lt 8 ] ; do
               eval usr=\$user$j
               rlRun "pki -d $CERTDB_DIR \
                          -n ${prefix}_adminV \
                          -c $CERTDB_DIR_PASSWORD \
 		   	  -h $SUBSYSTEM_HOST \
 		       	  -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                   	  -t kra \
                           user-del  '$usr' > $TmpDir/pki-user-del-kra-user-symbol-00$j.out" \
                           0 \
                           "Deleted user $usr"
		actual_delete_user_string=`cat $TmpDir/pki-user-del-kra-user-symbol-00$j.out | grep 'Deleted user' | xargs echo`
        	expected_delete_user_string="Deleted user $usr"
		if [[ $actual_delete_user_string = $expected_delete_user_string ]] ; then
                	rlPass "Deleted user \"$usr\" found in $TmpDir/pki-user-del-kra-user-symbol-00$j.out"
        	else
                	rlFail "Deleted user \"$usr\" not found in $TmpDir/pki-user-del-kra-user-symbol-00$j.out" 
        	fi
                let j=$j+1
        done
	#Deleting user idm_user_1
	local pki_user="idm1_user_1"
	rlRun "pki -d $CERTDB_DIR \
		-n ${prefix}_adminV \
		-c $CERTDB_DIR_PASSWORD \
		-h $SUBSYSTEM_HOST \
                -p $(eval echo \$${subsystemId}_UNSECURE_PORT) \
                -t kra \
		user-del $pki_user > $TmpDir/pki-user-del-user-kra-2_1.out" \
		0 \
		"Deleted user $pki_user"
	rlAssertGrep "Deleted user \"$pki_user\"" "$TmpDir/pki-user-del-user-kra-2_1.out"

	#Delete temporary directory
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
   else
	rlLog "KRA instance not created."
   fi
}
