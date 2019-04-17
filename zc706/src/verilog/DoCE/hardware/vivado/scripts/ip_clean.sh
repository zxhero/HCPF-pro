#!/bin/bash

IP_DIR="../sources/ip_catalog"

function ip_clean_func()
{
	if [ -d $IP_DIR/$1 ]
	then
		count=`ls $IP_DIR/$1/work | wc -w`
		if [ "$count" > "0" ]
		then
			rm -rf $IP_DIR/$1/work/*
		fi
	fi
}

ip_clean_func xgbe_rx_if/axis_async_fifo
ip_clean_func xgbe_rx_if/cmd_fifo_xgemac_rxif

