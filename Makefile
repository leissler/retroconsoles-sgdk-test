.PHONY: setup build clean test debug run

.DEFAULT_GOAL := build

setup:
	@./scripts/setup-native-sgdk.sh

build:
	@./scripts/sgdk-make.sh

clean:
	@./scripts/sgdk-make.sh clean

debug:
	@./scripts/sgdk-make.sh debug

test: build
	@./scripts/test-rom.sh

run: build
	@./scripts/run-rom.sh
