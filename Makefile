.PHONY: build icon dmg package-test smoke clean test

build:
	./scripts/build-release.sh

icon:
	./scripts/render-icon.sh

dmg:
	./scripts/build-dmg.sh

package-test:
	./scripts/package-test.sh

smoke:
	./scripts/smoke-test.sh

test:
	rm -rf .build
	mkdir -p .build
	/usr/bin/python3 -m py_compile Resources/sony_timecode_fixer.py
	/usr/bin/python3 Resources/sony_timecode_fixer.py --output-dir .build Examples/Basic/sample.fcpxml | tee .build/basic.out
	grep -q "1 Sony asset" .build/basic.out
	rm -rf .build/Sample.fcpxmld .build/*Fixed*.fcpxmld
	mkdir -p .build/Sample.fcpxmld
	cp Examples/Package/Info.fcpxml .build/Sample.fcpxmld/Info.fcpxml
	cp Examples/Package/C0001.MP4 .build/Sample.fcpxmld/C0001.MP4
	cp Examples/Package/C0001M01.XML .build/Sample.fcpxmld/C0001M01.XML
	/usr/bin/python3 Resources/sony_timecode_fixer.py --output-dir .build .build/Sample.fcpxmld | tee .build/package.out
	grep -q "1 Sony asset" .build/package.out

clean:
	./scripts/clean.sh
