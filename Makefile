include .env
export

.PHONY: deploy clean

%.bu: %.bu.yml .env
	envsubst < $< > $@

%.ign: %.bu
	docker run -i --pull=always --rm quay.io/coreos/butane:release --pretty --strict < $< > $@

deploy: config.ign
	./deploy.sh

clean:
	rm -f *.bu *.ign
