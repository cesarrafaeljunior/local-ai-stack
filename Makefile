.PHONY: bootstrap doctor light work code heavy code-heavy off status models backup update-webui

bootstrap:
	./scripts/bootstrap.sh
doctor:
	./scripts/ia doctor
light:
	./scripts/ia light
work:
	./scripts/ia work
code:
	./scripts/ia code
heavy:
	./scripts/ia heavy
code-heavy:
	./scripts/ia code-heavy
off:
	./scripts/ia off
status:
	./scripts/ia status
models:
	./scripts/ia models
backup:
	./scripts/ia backup
update-webui:
	./scripts/ia update-webui
