import { Fragment } from 'inferno';
import { useBackend, useSharedState } from '../backend';
import { AnimatedNumber, Box, Button, Flex, LabeledList, ProgressBar, Section, Slider, Tabs, Table } from '../components';
import { NtosWindow } from '../layouts';

export const NtosAiControl = (props, context) => {
  const { act, data } = useBackend(context);
  const { PC_device_theme } = data;
  return (
    <NtosWindow
      width={800}
      height={600}
      theme={PC_device_theme}>
      <NtosWindow.Content>
        <NtosAiControlContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};

export const NtosAiControlContent = (props, context) => {
  const { act, data } = useBackend(context);
  const [tab_main, setTab_main] = useSharedState(context, 'tab_main', 1);
  const [tab_sub, setTab_sub] = useSharedState(context, 'tab_sub', 1);
  const {
    name,
	integ,
	battery,
	shellcount,
	selectedborg,
    printerPictures,
	cyborgs = [],
	cyborgextended = [],
  } = data;
  const upgradearray = cyborgextended.length && cyborgextended.upgrades != null ? cyborgextended.upgrades.split(',') : [];
  const laws = data.laws || [];
  const borgLog = data.borgLog || [];
  const borgUpgrades = data.borgUpgrades || [];
  const borgColors = {
	"Engineering":"yellow",
	"Security":"darkred",
	"Medical":"blue",
	"Janitor":"purple",
	"Mining":"orange",
	"Default":"grey",
	"Service":"lightgreen",
	"Peacekeeper":"white",
	"Clown":"lightpink"
  }
  return (
    <Flex
      direction={"column"}>
      <Flex.Item
        position="relative"
        mb={1}>
        <Tabs>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={tab_main === 1}
            onClick={() => setTab_main(1)}>
            Control
          </Tabs.Tab>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={tab_main === 2}
            onClick={() => setTab_main(2)}>
            Logs
          </Tabs.Tab>
        </Tabs>
      </Flex.Item>
      {tab_main === 1 && (
        <Fragment>
          <Flex
            direction={"row"}>
                        <Flex.Item
              width="40%"
              ml={1}>
              <Section
                fitted>
                <Tabs
                  fluid={1}
                  textAlign="center">
                  <Tabs.Tab
                    icon=""
                    lineHeight="23px"
                    selected={tab_sub === 1}
                    onClick={() => setTab_sub(1)}>
                    Status
                  </Tabs.Tab>
                  <Tabs.Tab
                    icon=""
                    lineHeight="23px"
                    selected={tab_sub === 2}
                    onClick={() => setTab_sub(2)}>
                    Actions
                  </Tabs.Tab>
                  <Tabs.Tab
                    icon=""
                    lineHeight="23px"
                    selected={tab_sub === 3}
                    onClick={() => setTab_sub(3)}>
                    Config
                  </Tabs.Tab>
                </Tabs>
              </Section>
              {tab_sub === 1 && (
                <Section>
                  <LabeledList>
                    <LabeledList.Item
                      label="Unit">
                      {name}
                    </LabeledList.Item>
                    <LabeledList.Item
                      label="System Integrity">
                      {integ}%
                    </LabeledList.Item>
                    <LabeledList.Item
                      label="Backup Power">
                      {battery/2}%
                    </LabeledList.Item>
                    <LabeledList.Item
                      label="Remote Shells">
                      {shellcount}
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              )}
              {tab_sub === 2 && (
                <Section>
                  <LabeledList>
                    <LabeledList.Item
                      label="Toggle Floor Bolts">
                      <Button
                        content="DEBUG"
                        onClick={() => act('togglebolts')} />
                    </LabeledList.Item>
                    <LabeledList.Item
                      label="Set Status Display">
                      <Button
                        content="DEBUG"
                        onClick={() => act('setmonitors')} />
                    </LabeledList.Item>
                    <LabeledList.Item
                      label={"Stored Photos (" + printerPictures + ")"}>
                      <Button
                        content="View"
                        disabled={!printerPictures}
                        onClick={() => act('viewImage')} />
                      <Button
                        content="Print"
                        disabled={!printerPictures}
                        onClick={() => act('printImage')} />
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              )}
              {tab_sub === 3 && (
                <Section>
                  <LabeledList>
                    <LabeledList.Item
                      label="Change Hologram">
                      <Button
                        content="DEBUG"
                        onClick={() => act('changeholo')} />
                    </LabeledList.Item>
                    <LabeledList.Item
                      label="Set Core Display">
                      <Button
                        content="DEBUG"
                        onClick={() => act('changecore')} />
                    </LabeledList.Item>
                    <LabeledList.Item
                      label="Camera Acceleration">
                      <Button
                        content="Toggle"
                        onClick={() => act('togglecameraacc')} />
                    </LabeledList.Item>
                  </LabeledList>
                </Section>
              )}
            </Flex.Item>
            <Flex.Item
              //grow={1}
			  width={"40%"}
              ml={1}>
              <Section
                title="Cyborgs"
				height={20}>
				<NtosWindow.Content scrollable>
					{cyborgs.map(borg => (
						<Button
							compact
							iconColor={borg.status === 4 ? "red" : "lightgrey"}
							textAlign="center"
							align="center"
							icon={borg.status === 4 ? "exclamation-triangle" : borg.shell ? "upload" : ""}
							content={borg.name}
							color="transparent"
							style={{
								'border' : selectedborg === borg.ref && `1px solid ${borgColors[borg.designation] || "white"}`
							}}
							textColor={borgColors[borg.designation]}
							onClick={() => act('borgselect',{ref: borg.ref})} />
            //{borg.ref === selectedborg && cyborgextended.name = borg.name}
					))}
				</NtosWindow.Content>
              </Section>
            </Flex.Item>
            <Flex.Item
              width="50%"
              ml={1}>
              <Section
                title="Cyborg Status"
                height={20}>
                {selectedborg && (
                  <NtosWindow.Content scrollable>
                    <Table>
                      <tr>
                        <Box
                          as="td"
                          color='label'>
                        Unit:
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td">
                        {cyborgextended.name}
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td"
                          color='label'>
                        Designation:
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td">
                        {cyborgextended.designation}
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td"
                          color='label'>
                        Status:
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td"
                          color={cyborgextended.status === "ONLINE"? 'green' : cyborgextended.status === "LOCKED DOWN" ? 'yellow' : 'red'}>
                        {cyborgextended.status}
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td"
                          color='label'>
                        Charge:
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td"
                          color={cyborgextended.charge === "CELL NOT FOUND" || cyborgextended.charge < 20 ? 'red' : cyborgextended[0].charge < 40 ? 'yellow' : 'white'}>
                        {cyborgextended.charge}
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td"
                          color='label'>
                        Upgrades:
                        </Box>
                      </tr>
                      <tr>
                        <Box
                          as="td">
                          {upgradearray}
                          {upgradearray.map(upgrade => {
                            {upgrade}
                          })}
                          {cyborgextended.upgrades.split(',').map(stuff => {
                            {stuff}
                          })}
                        </Box>
                      </tr>
                    </Table>
                  </NtosWindow.Content>
                )}
              </Section>
            </Flex.Item>
          </Flex>
          <Flex.Item
            height={21}
            mt={1}>
            <Section
              title="Laws"
              fill
              scrollable
              buttons={(
                <Fragment>
                  <Button
                    content="State Laws"
                    onClick={() => act('lawstate')} />
                  <Button
                    icon="volume-off"
                    onClick={() => act('lawchannel')} />
                </Fragment>
              )}>
              {laws.map(law => (
                <Box
                  mb={1}
                  key={law}>
                  {law}
                </Box>
              ))}
            </Section>
          </Flex.Item>
        </Fragment>
      )}
      {tab_main === 2 && (
        <Flex.Item>
          <Section
            backgroundColor="black"
            height={40}>
            <NtosWindow.Content scrollable>
              {borgLog.map(log => (
                <Box
                  mb={1}
                  key={log}>
                  <font color="green">{log}</font>
                </Box>
              ))}
            </NtosWindow.Content>
          </Section>
        </Flex.Item>
      )}
    </Flex>
  );
};

