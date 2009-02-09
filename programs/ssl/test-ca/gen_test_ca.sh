#!/bin/sh
rm -rf index newcerts/*.pem serial *.req *.key *.crt crl.prm

touch index
echo "01" > serial

PASSWORD=PolarSSLTest

echo "Generating CA"
cat sslconf.txt > sslconf_use.txt 
echo "CN=PolarSSL Test CA" >> sslconf_use.txt

openssl req -config sslconf_use.txt -days 3653 -x509 -newkey rsa:2048 \
            -set_serial 0 -text -keyout test-ca.key -out test-ca.crt \
	    -passout pass:$PASSWORD

echo "Generating rest"
openssl genrsa -out server1.key 2048
openssl genrsa -out server2.key 2048
openssl genrsa -out client1.key 2048
openssl genrsa -out client2.key 2048

echo "Generating requests"
cat sslconf.txt > sslconf_use.txt 
echo "CN=PolarSSL Server 1" >> sslconf_use.txt
openssl req -config sslconf_use.txt -new -key server1.key -out server1.req

cat sslconf.txt > sslconf_use.txt 
echo "CN=PolarSSL Server 2" >> sslconf_use.txt
openssl req -config sslconf_use.txt -new -key server2.key -out server2.req

cat sslconf.txt > sslconf_use.txt 
echo "CN=PolarSSL Client 1" >> sslconf_use.txt
openssl req -config sslconf_use.txt -new -key client1.key -out client1.req

cat sslconf.txt > sslconf_use.txt 
echo "CN=PolarSSL Client 2" >> sslconf_use.txt
openssl req -config sslconf_use.txt -new -key client2.key -out client2.req

echo "Signing requests"
for i in server1 server2 client1 client2;
do
  openssl ca -config sslconf.txt -out $i.crt -passin pass:$PASSWORD \
	-batch -in $i.req
done

echo "Revoking firsts"
openssl ca -batch -config sslconf.txt -revoke server1.crt -passin pass:$PASSWORD
openssl ca -batch -config sslconf.txt -revoke client1.crt -passin pass:$PASSWORD
openssl ca -batch -config sslconf.txt -gencrl -out crl.pem -passin pass:$PASSWORD

echo "Verifying second"
openssl x509 -in server2.crt -text -noout
cat test-ca.crt crl.pem > ca_crl.pem
openssl verify -CAfile ca_crl.pem -crl_check server2.crt
rm ca_crl.pem

echo "Generating PKCS12"
openssl pkcs12 -export -in client2.crt -inkey client2.key \
                      -out client2.pfx -passout pass:$PASSWORD

rm *.old *.req sslconf_use.txt
