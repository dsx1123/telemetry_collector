#! /bin/bash

echo "Hello, please setup YANG Suite admin user."

echo -n "username: "
#read -r
ADMIN_USER="cisco"
echo "$ADMIN_USER"
echo -n "password: "
#read -s
PASS_ONE="cisco!123"
echo "$PASS_ONE"

#echo ""

#echo -n "confirm password: "
#read -s
PASS_TWO="cisco!123"
#echo "$PASS_TWO"

die() {
    echo "Exiting...."
    exit 1
}

if [ "${PASS_ONE}" != "${PASS_TWO}" ]
then
    echo "Password does not match"
    die
fi

echo -n "email: "
#read -r
ADMIN_EMAIL="yang@cisco.com"
echo -n "yang@cisco.com"
echo ""
echo ""

if [ -z "${ADMIN_EMAIL}" ]
then
    echo "Email required"
    die
fi

csr_config=yang.csr.conf
common_name=yang-cisco

cat > $csr_config <<EOF
[ req ]
default_bits        = 2048
default_md          = sha256
encrypt_key         = no
prompt              = no
distinguished_name  = $common_name

[ $common_name ]
C                   =US
ST                  =CA
O                   =Cisco
L                   =SanJose
CN                  =$common_name
OU                  =edge
emailAddress        =yang@cisco.com
EOF

echo "CSR Configuration Information:"
echo ""
cat ./$csr_config

if [ -f nginx/nginx-self-signed.cert ] && [ -f nginx/nginx-self-signed.key ]
then
    echo " "
    echo "Certificates already generated"
    echo " "
else
    #echo -n "Setup test certificates? (y/n): "
    #read -r
    YS_CERTS="y"
    if [ ! -f nginx/nginx-self-signed.cert ] && [ ! -f nginx/nginx-self-signed.key ]
    #if [ "${YS_CERTS}" == "y" ]
    then
        echo "################################################################"
        echo "## Generating self-signed certificates...                     ##"
        echo "##                                                            ##"
        echo "## WARNING: Obtain certificates from a trusted authority!     ##"
        echo "##                                                            ##"
        echo "## NOTE: Some browsers may still reject these certificates!!  ##"
        echo "################################################################"
        echo " "
        
        openssl req -config $csr_config -new -newkey rsa:2048 -nodes -keyout nginx/nginx-self-signed.key -out nginx-csr.csr
        openssl x509 -req -days 3650 -in nginx-csr.csr -signkey nginx/nginx-self-signed.key -out nginx/nginx-self-signed.cert
        
        #openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout nginx/nginx-self-signed.key -out nginx/nginx-self-signed.cert

        if [ -f nginx/nginx-self-signed.cert ] && [ -f nginx/nginx-self-signed.key ]
        then
            echo "Certificates generated..."
        else
            echo "Certificates not generated..."
            die
        fi
    else
        echo "Are key and certificate files in nginx/ directory with file names added to nginx/dockerfile and nginx/ssl-signed.conf? (y/n): "
        read -r
        CONTINUE=$REPLY

        if [ "${CONTINUE}" != "y" ]
        then
            die
        fi
    fi
fi

echo "Building docker containers..."

cat >"yangsuite/setup.env" <<%%
DJANGO_SETTINGS_MODULE=yangsuite.settings.production
MEDIA_ROOT=/ys-data/
STATIC_ROOT=/ys-static/
DJANGO_STATIC_ROOT=/ys-static/
DJANGO_ALLOWED_HOSTS=localhost
YS_ADMIN_USER=$ADMIN_USER
YS_ADMIN_PASS=$PASS_ONE
YS_ADMIN_EMAIL=$ADMIN_EMAIL
%%

#cat "yangsuite/setup.env"

docker-compose up --build
