echo "Oppretter scratch org"
call sf org create scratch --definition-file config\project-scratch-def.json --alias %1 --duration-days %2 --set-default --json --wait 30

echo "Installerer crm-platform-base ver. 0.218"
call sf package install --package 04t7U000000Y3esQAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-flowComponents ver. 0.4"
call sf package install --package 04t7U0000008qz4QAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installer crm-henvendelse-base ver. 0.20"
call sf package install --package 04t7U000000Y4EgQAK --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-journal-utilities ver. 0.27"
call sf package install --package 04t7U000000Y3hhQAC --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-shared-user-notification ver. 0.22"
call sf package install --package 04t7U000000D2E7QAK --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-integration ver. 0.100"
call sf package install --package 04t7U0000000RmdQAE --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-oppgave ver. 0.51"
call sf package install --package 04t7U000000Y3eOQAS --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-access-control ver. 0.113"
call sf package install --package 04t7U0000004e8tQAA --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-community-base ver. 0.92"
call sf package install --package 04t7U0000000RwEQAU --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Installerer crm-platform-reporting ver. 0.35"
call sf package install --package 04t7U000000Y2NpQAK --no-prompt --installation-key %3 --wait 30 --publish-wait 30

echo "Dytter kildekoden til scratch org'en"
call sf project deploy start

echo "Ferdig"
