import type { TabKey } from './types';
import { tabBarStyle, tabStyle } from '../common/parchment';

export const TabBar = (props: {
  tab: TabKey;
  onSwitch: (t: TabKey) => void;
}) => {
  const { tab, onSwitch } = props;
  return (
    <div style={tabBarStyle}>
      <div style={tabStyle(tab === 'orders')} onClick={() => onSwitch('orders')}>
        Заказы Экспорта
      </div>
      <div style={tabStyle(tab === 'market')} onClick={() => onSwitch('market')}>
        Рынок
      </div>
      <div style={tabStyle(tab === 'regions')} onClick={() => onSwitch('regions')}>
        Регионы
      </div>
      <div
        style={tabStyle(tab === 'auto_import')}
        onClick={() => onSwitch('auto_import')}
      >
        Авто-Иморт
      </div>
      <div
        style={tabStyle(tab === 'petition')}
        onClick={() => onSwitch('petition')}
      >
        Петиции
      </div>
    </div>
  );
};
