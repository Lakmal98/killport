VERSION ?= 0.4
PACKAGE_DIR := killport
DEB_NAME := killport.$(VERSION).deb

install:
	mkdir -p $(PACKAGE_DIR)/usr/local/bin
	cp killport.sh $(PACKAGE_DIR)/usr/local/bin/
	mv $(PACKAGE_DIR)/usr/local/bin/killport.sh $(PACKAGE_DIR)/usr/local/bin/killport
	chmod +x $(PACKAGE_DIR)/usr/local/bin/killport
	mkdir -p $(PACKAGE_DIR)/DEBIAN
	echo "Package: killport\nVersion: $(VERSION)\nSection: base\nPriority: optional\nArchitecture: all\nDepends: bash, lsof\nMaintainer: Dimuthu Lakmal <lakmalepp@gmail.com>\nDescription: A script to terminate processes associated with ports" > $(PACKAGE_DIR)/DEBIAN/control
	echo "#!/bin/bash\nln -sf /usr/local/bin/killport /usr/bin/killport" > $(PACKAGE_DIR)/DEBIAN/postinst
	chmod +x $(PACKAGE_DIR)/DEBIAN/postinst
	dpkg-deb --build $(PACKAGE_DIR) $(DEB_NAME)


test:
	bash tests/run.sh
