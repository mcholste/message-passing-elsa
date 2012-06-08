log-stash-elsa
==============

Message-Passing-Output-ELSA

This is an output plugin for the Log::Stash or Message::Passing framework to store logs in ELSA in either batch mode or realtime processing.  To test, you can run something like this:

echo '{"timestamp":1, "host":"127.0.0.1", "program":"test", "class_id":1, "msg": "test message"}' | message-pass --input STDIN --output ELSA --output_options '{"config_file":"/etc/elsa_node.conf", "inc":"/usr/local/elsa/node"}'
