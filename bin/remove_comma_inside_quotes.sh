#!/bin/sh
perl -pe 's:"(\d[\d,]+)":$1=~y/,//dr:eg'
