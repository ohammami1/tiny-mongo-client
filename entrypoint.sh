#!/usr/bin/env bash

# MONGO_USER: User for the current APP
# MONGO_PASS: Password for the current User
# MONGO_DATABASE: Current App Database

function to_int {
	local -i num="10#${1}"
	echo "${num}"
}

if [ -z $ENV ]; then
	export ENV="local"
fi

if [ $ENV != 'prod' ] && [ $ENV != 'dev' ] && [ $ENV != 'local' ]; then
	echo "ENV envvar must be set before running this test"
	exit 1
fi

if [ -z "$MONGO_HOST" ]; then
	export MONGO_HOST=mongo_server
else
	if ! ping -c 1 $MONGO_HOST >/dev/null 2>&1 ; then
		echo "Mongo Host unreachable, exiting.."
		exit 1
	fi
fi

if [ -z "$MONGO_PORT" ]; then
	echo "MONGO_PORT not set, using default 27017"
	export MONGO_PORT=27017
else 
	port_num=$(to_int "${MONGO_PORT}" 2>/dev/null)

	if (( $port_num < 1 || $port_num > 65535 )); then
		echo "MONGO_PORT isn't a valid port, exiting.." 
		exit 1
	fi

	export MONGO_PORT=$port_num
fi

echo "Testing Mongo Connection in $ENV"

echo "Checking Connectivity"
COUNTER=0

if [ $ENV == 'local' ]; then
	while [[ $COUNTER -lt 60 ]]; do
		echo "Waiting mongo to initialize... ($COUNTER seconds so far)"

		if echo ''| mongo $MONGO_HOST:$MONGO_PORT/admin --quiet >/dev/null 2>&1; then
			break
		fi
	
		sleep 2
		let COUNTER+=2
	done
	if ! echo ''| mongo $MONGO_HOST:$MONGO_PORT/admin --quiet >/dev/null 2>&1; then
		echo "Unable to connect to mongodb service, exiting"
		exit 1
	fi

	echo "Connection for Root User Seems to Work" 
fi


if ! echo ''| mongo $MONGO_HOST:$MONGO_PORT/$MONGO_DATABASE \
	-u ${MONGO_USER} \
	-p ${MONGO_PASS} \
	--authenticationDatabase "admin" \
	--quiet >/dev/null 2>&1; then

	if [ $ENV != 'local' ]; then
		echo "User Credentials for $MONGO_USER dosen't seem to work, exiting.."
		exit 1
	fi

	echo "User Credentials does not seem to work, creating User with new Creds.."
	echo -e "db.dropUser('${MONGO_USER}');
		db.createUser({
			user: '${MONGO_USER}',
			pwd: '${MONGO_PASS}',
			roles: [{
				role: 'readWrite',
				db: '${MONGO_DATABASE}'
			}]
		});" |  mongo $MONGO_HOST:$MONGO_PORT/admin \
			--quiet >/dev/null 2>&1;

	# TODO: Check If User Created
else
	echo "User $MONGO_USER Credentials Validated"
fi

echo "Mongo hook finished"

# [For Debug]
#while true; do 
#	sleep 2
#done
