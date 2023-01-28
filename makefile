install:
	mkdir -p killport/usr/local/bin
	cp killport.sh killport/usr/local/bin/
	mv killport/usr/local/bin/killport.sh killport/usr/local/bin/killport
	chmod +x killport/usr/local/bin/killport
	mkdir -p killport/DEBIAN
	echo "Package: killport\nVersion: 0.3\nSection: base\nPriority: optional\nArchitecture: all\nDepends: bash\nMaintainer: Dimuthu Lakmal <lakmalepp@gmail.com>\nDescription: A script to kill process associated with a port" > killport/DEBIAN/control
	echo "#!/bin/bash\nln -s /usr/local/bin/killport.sh /usr/bin/killport" > killport/DEBIAN/postinst
	chmod +x killport/DEBIAN/postinst
	dpkg-deb --build killport killport.0.3.deb
