.PHONY: bootstrap doctor work light heavy off status models backup update-webui

bootstrap:
	./scripts/bootstrap.sh

doctor:
	./scripts/ia doctor

work:
	./scripts/ia work

light:
	./scripts/ia light

heavy:
	./scripts/ia heavy

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
