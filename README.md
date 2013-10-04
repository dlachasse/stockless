# Visr Checker usage

This tool will go to Visr.net and pull inventory at regular intervals. It's purpose is to notify buyer when inventory is replenished.

This tool is e-mail based and is configured to use visr.checker@gmail.com. Make sure everything that you send is on the first line of the email otherwise it will be ignored.

## Intervals

A report with all checked SKUs are sent every 24 hours. You can change this interval at any time by emailing a new hourly rate. Be sure to use the following format: `schedule: 6h`. This will send the report every 6 hours. You can also run in it minutes by using `m` or days by using `d`.

## Adding/Removing Products

To add an item to be checked just enter its UPC. If there are multiple items you would like to add, be sure to separate them with commas. These UPCs will be continually checked until they are deleted. In order to remove them from the list, just place a `d` after the UPC code. Here is an example email:

`00038257086065,00038257086089,00038257086072,00038257086058,38257752533d,38257752540d`

It doesn't matter if you have the 0's in front or not. As far as the system is concerned `00038257086065` is the same as `38257086065`.

## Add new email addresses

To add a new email address – just as with the time interval change you must email in the following format: `add user example@gmail.com`.

### Instructions

To be resent instructions email `send instructions`. They will be sent to whatever address sends this.
