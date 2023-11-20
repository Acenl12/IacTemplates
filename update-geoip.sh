#!/bin/bash

# Create temporary directory
mkdir -p /usr/share/xt_geoip/tmp/
mkdir -p /usr/share/xt_geoip/tmp/ip2loc/

# Download latest from db-ip.com
cd /usr/share/xt_geoip/tmp/
/usr/lib/xtables-addons/xt_geoip_dl

# Download maxmind legacy csv and process
wget https://mailfud.org/geoip-legacy/GeoIP-legacy.csv.gz -O /usr/share/xt_geoip/tmp/GeoIP-legacy.csv.gz
gunzip /usr/share/xt_geoip/tmp/GeoIP-legacy.csv.gz
cat /usr/share/xt_geoip/tmp/GeoIP-legacy.csv | tr -d '"' | cut -d, -f1,2,5 > /usr/share/xt_geoip/tmp/GeoIP-legacy-processed.csv
rm /usr/share/xt_geoip/tmp/GeoIP-legacy.csv
rm /usr/share/xt_geoip/tmp/GeoIP-legacy.csv.gz

# Download latest from https://github.com/sapics/ip-location-db
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/geo-whois-asn-country/geo-whois-asn-country-ipv4.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/geo-whois-asn-country/geo-whois-asn-country-ipv6.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/iptoasn-country/iptoasn-country-ipv4.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/iptoasn-country/iptoasn-country-ipv6.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/dbip-country/dbip-country-ipv4.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/dbip-country/dbip-country-ipv6.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/geolite2-country/geolite2-country-ipv4.csv
wget -P /usr/share/xt_geoip/tmp/ https://cdn.jsdelivr.net/npm/@ip-location-db/geolite2-country/geolite2-country-ipv6.csv

# Combine all csv and remove duplicates
cd /usr/share/xt_geoip/tmp/
cat *.csv > geoip.csv
sort -u geoip.csv -o /usr/share/xt_geoip/dbip-country-lite.csv

# Remove temp directory and update geoip xtables
rm -r /usr/share/xt_geoip/tmp/
/usr/lib/xtables-addons/xt_geoip_build -D /usr/share/xt_geoip/ -S /usr/share/xt_geoip/
rm /usr/share/xt_geoip/dbip-country-lite.csv

# reload ufw
# ufw reload
