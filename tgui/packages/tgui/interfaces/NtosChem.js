import { filter, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { toFixed } from 'common/math';
import { useBackend } from '../backend';
import { Button, Flex, LabeledList, ProgressBar, Section } from '../components';
import { getGasColor, getGasLabel } from '../constants';
import { NtosWindow } from '../layouts';

export const NtosChem = (props, context) => {
  return (
    <NtosWindow
      width={800}
      height={600}
      theme="ntos">
      <br></br>
      <br></br>
      <NtosChemContent/>
    </NtosWindow>
  );
};

export const NtosChemContent = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    reagentslist = [],
    containerinfo = [],
    errorlevel,
    absolute_percentage,
  } = data;
  return (
    <Flex
      direction={"column"}
      hight="100%">
      <Flex.Item
        position="relative"
        m={1}>
        <Section
          title="Basic Properties">
          <LabeledList>
            <LabeledList.Item
              label="Container Volume">
              {containerinfo["volume"]}
            </LabeledList.Item>
            <LabeledList.Item
              label="Volume Filled">
              {containerinfo["usedvolume"]}
            </LabeledList.Item>
            <LabeledList.Item
              label="Reagent Temperature">
              {containerinfo["temp"]}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Flex.Item>
      <Flex.Item
        position="relative"
        m={1}
        width={45}
        height={45}
        fill>
        <Section
          title="Chemical Makeup"
          buttons={(
            <Button
              content={absolute_percentage?"Change to Relative":"Change to Absolute"}
              onClick={() => act('percentage')} />
          )}>
          {reagentslist.map(reagent => (
            <div>
            found a chem {reagent.map(something => (
              <div>
              {something}
              </div>
            ))}
            </div>
          ))}
        </Section>
      </Flex.Item>
    </Flex>
  );
};
