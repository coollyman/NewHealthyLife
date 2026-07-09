import abilityTest from './Ability.test';
import deviceIntegrationTest from './DeviceIntegration.test';

export default function testsuite() {
  abilityTest();
  deviceIntegrationTest();
}
