#Adding swap space in branded zone
root@globalzone # prctl -n zone.max-swap -i zone localzone
root@globalzone # prctl -n zone.max-swap -r -v 10gb -i zone localzone
root@globalzone # prctl -n zone.max-swap -i zone localzone
root@globalzone # zonecfg -z localzone
zonecfg:localzone> select capped-memory
zonecfg:localzone:capped-memory> set swap=10g
zonecfg:localzone:capped-memory> info
zonecfg:localzone:capped-memory> end
zonecfg:localzone> verify
root@globalzone # commit
root@globalzone # exit