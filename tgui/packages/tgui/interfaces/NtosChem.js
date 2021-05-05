import { useBackend, useSharedState } from '../backend';
import { AnimatedNumber, Box, Button, Flex, LabeledList, ProgressBar, Section, Slider, Tabs } from '../components';
import { NtosWindow } from '../layouts';

export const NtosChem = (props, context) => {
  const { act, data } = useBackend(context);
  const { PC_device_theme } = data;
  return (
    <NtosWindow
      width={800}
      height={600}
      theme={PC_device_theme}>
      <NtosWindow.Content>
        <NtosChemContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};

export const NtosChemContent = (props, context) => {
  const { act, data } = useBackend(context);
  const reagent_info = data.reagent_info || [];
  const container_info = data.container_info || [];
  return (
    <Flex
      direction={"row"}>
      <Flex.Item
        position="relative"
        mb={1}>
        <LabeledList>
          {reagent_info.map(chem => (
            <LabeledList.Item
              label='chem.name'>
              {chem.volume}
            </LabeledList.Item>
          ))}
        </LabeledList>
      </Flex.Item>
    </Flex>
  );
};

