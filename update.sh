#! /bin/bash

pixi self-update
pixi clean cache --conda
pixi update
pixi clean cache --conda
(cd ~/.cache/rattler/ && rm -rf *)
pixi shell
