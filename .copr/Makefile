# target used by copr make_rpm 
srpm:
	@echo "PWD: $(PWD)"
	dnf -y install rpm-build spectool
	spectool -g -C $(outdir) $(spec)
	rpmbuild -bs --define "_sourcedir $(outdir)" --define "_srcrpmdir $(outdir)" $(spec)


# #############################
# local dev targets

ARCHES ?= x86_64 aarch64

rpm:
	$(eval file := $(shell ls $(outdir)/onekey-wallet-bin-*.src.rpm | head -n1))
	@echo "Using $(file)"
	dnf builddep -y $(file)
	rpmbuild --rebuild --define "_sourcedir $(outdir)" --define "_rpmdir $(outdir)" $(file)

rpm-mock-arches:
	$(eval ARCHES := x86_64 aarch64)
	@echo "ARCHES=$(ARCHES)"
	@for a in $(ARCHES); do echo $$a; done

rpm-mock:
	@echo "Building $(spec) in mock"
	# mock doesnt like beeing run in container, give it more privileges
	mock --root fedora-44-aarch64 --resultdir $(outdir)/mock/ --rebuild $(outdir)/onekey-wallet-bin-*.src.rpm --enable-network
