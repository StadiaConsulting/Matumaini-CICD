# Add INSPECT to check return value.  Need to figure out what makes sense for terraform
INSPECT := $$(docker-compose -p $$1 -f $$2 ps -q $$3 | xargs -I ARGS docker inspect -f "{{ .State.ExitCode }}" ARGS)

# Add CHECK in conjunction with INSPECT
CHECK := @base -c '\
	if [[ $(INSPECT) -ne 0 ]]; \
	then exit $(INSPECT); fi' VALUE

.PHONY: cicd-build clean cicd-plan matumaini

cicd-build:
		${INFO} "building CICD infrastructure"
		@ terraform apply
		${INFO} "build complete"

clean:
	${INFO} "cleaning"
	@ terraform destroy
	${INFO} "clean compete"

cicd-plan:
		${INFO} "building CICD infrastructure"
		@ terraform plan
		${INFO} "build complete"

matumaini:
		${INFO} "building docker image"
		@ matumaini-app.sh
		${INFO} "build complete"

# Cosmetics - Setting colors to be used in output
# list of colors - https://misc.flogisoft.com/bash/tip_colors_and_formatting
YELLOW := "\e[1;33m"
NC := "\e[0m"

# Shell Functions
INFO := @bash -c '\
	printf $(YELLOW); \
	echo "==> $$1"; \
	printf $(NC)' VALUE
