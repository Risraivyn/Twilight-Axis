import { useState } from 'react';
import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type TreeNode = {
  id: string;
  name: string;
  desc: string;
  cost: number;
  x: number;
  y: number;
  parent: string | null;
};

type SandmanData = {
  essence: number;
  total_essence: number;
  ascension_goal: number;
  ascended: boolean;
  unlocked: Record<string, boolean>;
  nodes: TreeNode[];
};

export const SandmanTree = () => {
  const { act, data } = useBackend<SandmanData>();
  const {
    essence = 0,
    total_essence = 0,
    ascension_goal = 25,
    ascended = false,
    unlocked = {},
    nodes = [],
  } = data;
  const [selectedId, setSelectedId] = useState<string>('core');

  const centerX = 330;
  const centerY = 230;
  const selectedNode = nodes.find((n) => n.id === selectedId) || nodes[0];

  const isAvailable = (node: TreeNode) => {
    if (unlocked[node.id]) return false;
    if (node.parent && !unlocked[node.parent]) return false;
    return essence >= node.cost;
  };

  return (
    <Window title="Древо Кошмаров" width={720} height={600}>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Древо Кошмаров">
              <Stack justify="space-between" align="center">
                <Stack.Item>
                  <Box fontSize="14px">
                    Доступная Сущность: <b>{essence}</b>
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box fontSize="14px" color={ascended ? 'purple' : 'label'}>
                    {ascended
                      ? 'ВОЗВЫШЕН (способности доступны всегда)'
                      : `Возвышение: ${total_essence} / ${ascension_goal}`}
                  </Box>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>

          <Stack.Item grow>
            <Section fill>
              <Box
                position="relative"
                width="100%"
                height="350px"
                style={{
                  overflow: 'hidden',
                  background: '#0e0a14',
                  borderRadius: '6px',
                }}
              >
                <svg
                  width="100%"
                  height="100%"
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    pointerEvents: 'none',
                  }}
                >
                  {nodes.map((node) => {
                    if (!node.parent) return null;
                    const parentNode = nodes.find((p) => p.id === node.parent);
                    if (!parentNode) return null;
                    const active = unlocked[node.id] || unlocked[parentNode.id];
                    return (
                      <line
                        key={`${parentNode.id}-${node.id}`}
                        x1={centerX + parentNode.x}
                        y1={centerY + parentNode.y}
                        x2={centerX + node.x}
                        y2={centerY + node.y}
                        stroke={
                          unlocked[node.id]
                            ? '#b366ff'
                            : active
                              ? '#5c3c80'
                              : '#2a2235'
                        }
                        strokeWidth={unlocked[node.id] ? 3 : 2}
                      />
                    );
                  })}
                </svg>

                {nodes.map((node) => {
                  const isOwned = !!unlocked[node.id];
                  const canBuy = isAvailable(node);
                  const isSelected = selectedId === node.id;

                  return (
                    <Button
                      key={node.id}
                      onClick={() => setSelectedId(node.id)}
                      color={isOwned ? 'purple' : canBuy ? 'good' : 'transparent'}
                      style={{
                        position: 'absolute',
                        left: `${centerX + node.x - 55}px`,
                        top: `${centerY + node.y - 18}px`,
                        width: '110px',
                        textAlign: 'center',
                        border: isSelected
                          ? '2px solid #ffffff'
                          : '1px solid #6b4c9a',
                        opacity:
                          isOwned ||
                          canBuy ||
                          !node.parent ||
                          unlocked[node.parent]
                            ? 1
                            : 0.45,
                      }}
                    >
                      {node.name}
                    </Button>
                  );
                })}
              </Box>
            </Section>
          </Stack.Item>

          {selectedNode && (
            <Stack.Item>
              <Section title={selectedNode.name}>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box>{selectedNode.desc}</Box>
                    <Box color="label" mt={0.5}>
                      Стоимость: {selectedNode.cost} Сущности
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    {unlocked[selectedNode.id] ? (
                      <Button disabled color="purple">
                        Изучено
                      </Button>
                    ) : (
                      <Button
                        color="good"
                        disabled={!isAvailable(selectedNode)}
                        onClick={() => act('buy_node', { id: selectedNode.id })}
                      >
                        Пробудить ({selectedNode.cost})
                      </Button>
                    )}
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};
