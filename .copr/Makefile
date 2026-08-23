# target used by copr make_rpm 
srpm:
	@echo "PWD: $(PWD)"
	dnf -y install rpm-build spectool
	spectool -g -C $(outdir) $(spec)
	rpmbuild -bs --define "_sourcedir $(outdir)" --define "_srcrpmdir $(outdir)" $(spec)
