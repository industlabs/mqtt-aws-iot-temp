PORT=/dev/cu.usbserial-0001
FIRMWARE=esp32-idf3-20191220-v1.12.bin

provision:
	cd terraform && \
	terraform apply && \
	cd ..

flash:
	wget -N https://micropython.org/resources/firmware/$(FIRMWARE) && \
	esptool.py --chip esp32 --port $(PORT) erase_flash && \
	esptool.py --chip esp32 --port $(PORT) --baud 921600 write_flash --flash_size=detect -z 0x1000 $(FIRMWARE)

props:
	cd terraform && \
	terraform output -json private_key | jq -r . | openssl rsa -outform DER -out ../app/private_key.der && \
	terraform output -json cert_pem | jq -r . | openssl x509 -outform DER -out ../app/cert.der && \
	ENDPOINT=`terraform output -json iot_endpoint | jq -r .` && \
	sed 's|<IOT_ENDPOINT>|'$$ENDPOINT'|' ../app/props.json.tmpl > ../app/props.json && \
	cd ..

upload: props
	rshell -p $(PORT) --quiet cp app/* /pyboard/