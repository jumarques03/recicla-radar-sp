// GERADO por tool/gerar_distritos.py. Não edite à mão: rode o script de novo.
//
// Cada distrito de São Paulo (relação do OpenStreetMap), com o ponto do rótulo e
// os pontos de descarte que ficam dentro dele.

typedef PointSeed = (String name, double lat, double lng, int intensity);
typedef DistrictSeed = (
  int osmId,
  String name,
  double lat,
  double lng,
  List<PointSeed> points,
);

const List<DistrictSeed> districtSeeds = [
  (3049346, 'Alto de Pinheiros', -23.54774, -46.71153, [
      ('Terminal de ônibus de Alto de Pinheiros', -23.53924, -46.71295, 6),
      ('Mercado de Alto de Pinheiros', -23.55967, -46.70370, 5),
  ]),
  (3049157, 'Anhanguera', -23.43133, -46.79241, [
      ('Terminal de ônibus de Anhanguera', -23.45428, -46.78518, 3),
      ('Parque de Anhanguera', -23.40299, -46.81792, 2),
      ('Mercado de Anhanguera', -23.41569, -46.77713, 3),
      ('Feira livre de Anhanguera', -23.43404, -46.81150, 2),
  ]),
  (3049436, 'Aricanduva', -23.57452, -46.51576, [
      ('Praça central de Aricanduva', -23.56751, -46.51919, 4),
      ('Avenida principal de Aricanduva', -23.58675, -46.50887, 5),
  ]),
  (3049500, 'Artur Alvim', -23.54062, -46.48475, [
      ('Terminal de ônibus de Artur Alvim', -23.53197, -46.48075, 3),
      ('Praça central de Artur Alvim', -23.54733, -46.49803, 4),
  ]),
  (3049347, 'Barra Funda', -23.52147, -46.67421, [
      ('Avenida principal de Barra Funda', -23.52978, -46.66731, 6),
      ('Terminal de ônibus de Barra Funda', -23.51158, -46.69038, 7),
  ]),
  (2731072, 'Bela Vista', -23.56074, -46.64768, [
      ('Parque de Bela Vista', -23.56562, -46.64683, 8),
      ('Feira livre de Bela Vista', -23.55438, -46.64862, 7),
  ]),
  (3049437, 'Belém', -23.53793, -46.59533, [
      ('Terminal de ônibus de Belém', -23.53739, -46.60415, 8),
      ('Parque de Belém', -23.54958, -46.58234, 8),
  ]),
  (2731073, 'Bom Retiro', -23.52584, -46.63688, [
      ('Praça central de Bom Retiro', -23.52804, -46.63327, 8),
      ('Feira livre de Bom Retiro', -23.52080, -46.64973, 7),
  ]),
  (3049348, 'Brasilândia', -23.45046, -46.69008, [
      ('Terminal de ônibus de Brasilândia', -23.47180, -46.68492, 5),
      ('Avenida principal de Brasilândia', -23.42117, -46.68055, 5),
      ('Parque de Brasilândia', -23.44481, -46.70538, 5),
  ]),
  (2731074, 'Brás', -23.54347, -46.61806, [
      ('Parque de Brás', -23.54887, -46.62050, 7),
      ('Mercado de Brás', -23.53591, -46.61299, 7),
  ]),
  (3049349, 'Butantã', -23.56936, -46.72475, [
      ('Cidade Universitária (USP)', -23.56000, -46.73000, 7),
      ('Terminal de ônibus de Butantã', -23.58250, -46.74677, 4),
      ('Mercado de Butantã', -23.57826, -46.71164, 7),
  ]),
  (3049350, 'Cachoeirinha', -23.45544, -46.66186, [
      ('Terminal de ônibus de Cachoeirinha', -23.45864, -46.66527, 4),
      ('Parque de Cachoeirinha', -23.42118, -46.67311, 4),
      ('Feira livre de Cachoeirinha', -23.48051, -46.65863, 6),
  ]),
  (2731075, 'Cambuci', -23.56426, -46.61637, [
      ('Feira livre de Cambuci', -23.55996, -46.62027, 7),
      ('Mercado de Cambuci', -23.57559, -46.62070, 8),
  ]),
  (1692131, 'Campo Belo', -23.62720, -46.66791, [
      ('Mercado de Campo Belo', -23.62773, -46.68170, 5),
      ('Parque de Campo Belo', -23.63077, -46.65140, 5),
      ('Feira livre de Campo Belo', -23.63982, -46.66823, 6),
  ]),
  (1692132, 'Campo Grande', -23.67426, -46.68872, [
      ('Terminal de ônibus de Campo Grande', -23.67479, -46.68111, 5),
      ('Praça central de Campo Grande', -23.66596, -46.70699, 5),
      ('Feira livre de Campo Grande', -23.69477, -46.68792, 4),
  ]),
  (3032203, 'Campo Limpo', -23.63640, -46.76367, [
      ('Terminal Campo Limpo', -23.62400, -46.75700, 6),
      ('Praça central de Campo Limpo', -23.64691, -46.78448, 2),
      ('Terminal de ônibus de Campo Limpo', -23.64616, -46.75995, 4),
  ]),
  (3049438, 'Cangaíba', -23.49891, -46.51805, [
      ('Parque de Cangaíba', -23.50724, -46.52148, 4),
      ('Mercado de Cangaíba', -23.48067, -46.50396, 3),
      ('Feira livre de Cangaíba', -23.50378, -46.49720, 5),
  ]),
  (4484407, 'Capão Redondo', -23.66925, -46.78162, [
      ('Terminal Capão Redondo', -23.65900, -46.77900, 5),
      ('Praça central de Capão Redondo', -23.69140, -46.79519, 2),
      ('Avenida principal de Capão Redondo', -23.65167, -46.75657, 3),
  ]),
  (3049439, 'Carrão', -23.55067, -46.53723, [
      ('Mercado de Carrão', -23.55278, -46.52813, 6),
      ('Praça central de Carrão', -23.53918, -46.55453, 5),
  ]),
  (3049351, 'Casa Verde', -23.50192, -46.65768, [
      ('Mercado de Casa Verde', -23.50919, -46.66109, 7),
      ('Terminal de ônibus de Casa Verde', -23.48488, -46.65614, 7),
  ]),
  (1692133, 'Cidade Ademar', -23.67482, -46.65657, [
      ('Praça central de Cidade Ademar', -23.67028, -46.66720, 5),
      ('Avenida principal de Cidade Ademar', -23.67656, -46.63161, 5),
      ('Mercado de Cidade Ademar', -23.65019, -46.67252, 6),
  ]),
  (2715904, 'Cidade Dutra', -23.72524, -46.70033, [
      ('Avenida principal de Cidade Dutra', -23.72835, -46.70293, 2),
      ('Mercado de Cidade Dutra', -23.76194, -46.72177, 2),
      ('Parque de Cidade Dutra', -23.70608, -46.67364, 2),
      ('Terminal de ônibus de Cidade Dutra', -23.69975, -46.69820, 2),
  ]),
  (3049501, 'Cidade Líder', -23.56213, -46.49205, [
      ('Terminal de ônibus de Cidade Líder', -23.55407, -46.46743, 3),
      ('Praça central de Cidade Líder', -23.55495, -46.51248, 4),
      ('Mercado de Cidade Líder', -23.57661, -46.49028, 4),
  ]),
  (3049440, 'Cidade Tiradentes', -23.58399, -46.40136, [
      ('Parque de Cidade Tiradentes', -23.59055, -46.41065, 2),
      ('Praça central de Cidade Tiradentes', -23.57373, -46.38358, 2),
      ('Feira livre de Cidade Tiradentes', -23.56503, -46.40987, 3),
  ]),
  (2731076, 'Consolação', -23.54911, -46.66001, [
      ('Terminal de ônibus de Consolação', -23.54806, -46.65831, 8),
      ('Avenida principal de Consolação', -23.55001, -46.67213, 8),
  ]),
  (1901921, 'Cursino', -23.62975, -46.62027, [
      ('Avenida principal de Cursino', -23.61394, -46.61914, 6),
      ('Terminal de ônibus de Cursino', -23.66115, -46.62915, 4),
      ('Praça central de Cursino', -23.63854, -46.61811, 6),
  ]),
  (3049441, 'Ermelino Matarazzo', -23.49146, -46.48470, [
      ('Praça central de Ermelino Matarazzo', -23.49746, -46.47157, 4),
      ('Mercado de Ermelino Matarazzo', -23.47985, -46.49662, 5),
      ('Avenida principal de Ermelino Matarazzo', -23.50337, -46.49121, 3),
  ]),
  (3049442, 'Freguesia do Ó', -23.48680, -46.69803, [
      ('Praça central de Freguesia do Ó', -23.49166, -46.70623, 6),
      ('Mercado de Freguesia do Ó', -23.48004, -46.67794, 5),
      ('Terminal de ônibus de Freguesia do Ó', -23.46395, -46.70493, 6),
  ]),
  (2715905, 'Grajaú', -23.78986, -46.66903, [
      ('Mercado de Grajaú', -23.79869, -46.64134, 2),
      ('Avenida principal de Grajaú', -23.72352, -46.66253, 2),
      ('Terminal de ônibus de Grajaú', -23.84805, -46.69059, 2),
      ('Parque de Grajaú', -23.77559, -46.70912, 2),
  ]),
  (3049443, 'Guaianases', -23.55606, -46.40548, [
      ('Avenida principal de Guaianases', -23.55997, -46.40117, 2),
      ('Mercado de Guaianases', -23.54420, -46.42217, 2),
      ('Terminal de ônibus de Guaianases', -23.56153, -46.42311, 2),
  ]),
  (3049444, 'Iguatemi', -23.61324, -46.42596, [
      ('Parque de Iguatemi', -23.60310, -46.42678, 2),
      ('Feira livre de Iguatemi', -23.63918, -46.42304, 2),
      ('Praça central de Iguatemi', -23.61872, -46.40098, 2),
  ]),
  (3049352, 'Ipiranga', -23.59150, -46.60285, [
      ('Feira livre de Ipiranga', -23.59472, -46.60537, 6),
      ('Praça central de Ipiranga', -23.60824, -46.58318, 7),
      ('Terminal de ônibus de Ipiranga', -23.57111, -46.60762, 8),
  ]),
  (1694376, 'Itaim Bibi', -23.60268, -46.68633, [
      ('Avenida principal de Itaim Bibi', -23.60096, -46.68445, 7),
      ('Praça central de Itaim Bibi', -23.62240, -46.69116, 6),
      ('Feira livre de Itaim Bibi', -23.58068, -46.67472, 6),
  ]),
  (3049445, 'Itaim Paulista', -23.50407, -46.38622, [
      ('Feira livre de Itaim Paulista', -23.51206, -46.38906, 2),
      ('Mercado de Itaim Paulista', -23.48553, -46.37882, 2),
      ('Praça central de Itaim Paulista', -23.50532, -46.36812, 2),
  ]),
  (3049502, 'Itaquera', -23.53480, -46.45541, [
      ('Terminal Itaquera', -23.54000, -46.47100, 8),
      ('Arena Corinthians', -23.54530, -46.47420, 7),
      ('Parque de Itaquera', -23.52890, -46.43417, 2),
  ]),
  (1692134, 'Jabaquara', -23.65216, -46.64744, [
      ('Terminal Jabaquara', -23.66790, -46.64100, 9),
      ('Feira livre do Jabaquara', -23.64200, -46.64300, 6),
      ('Mercado de Jabaquara', -23.64772, -46.66831, 6),
  ]),
  (3049353, 'Jaguara', -23.51172, -46.74778, [
      ('Avenida principal de Jaguara', -23.51608, -46.74793, 6),
      ('Feira livre de Jaguara', -23.50282, -46.75950, 5),
  ]),
  (3049354, 'Jaguaré', -23.54487, -46.74827, [
      ('Parque de Jaguaré', -23.54460, -46.75403, 5),
      ('Terminal de ônibus de Jaguaré', -23.54932, -46.73492, 6),
  ]),
  (3049446, 'Jaraguá', -23.44555, -46.74051, [
      ('Parque de Jaraguá', -23.44555, -46.74051, 3),
      ('Praça central de Jaraguá', -23.42124, -46.70492, 5),
      ('Feira livre de Jaraguá', -23.46852, -46.77446, 2),
      ('Avenida principal de Jaraguá', -23.44955, -46.71216, 5),
  ]),
  (3049447, 'Jardim Helena', -23.48384, -46.41580, [
      ('Avenida principal de Jardim Helena', -23.48587, -46.42213, 2),
      ('Praça central de Jardim Helena', -23.47940, -46.38247, 2),
      ('Mercado de Jardim Helena', -23.49078, -46.40039, 2),
  ]),
  (3049355, 'Jardim Paulista', -23.56678, -46.66527, [
      ('Mercado de Jardim Paulista', -23.55766, -46.67436, 7),
      ('Praça central de Jardim Paulista', -23.57925, -46.66621, 7),
  ]),
  (3032210, 'Jardim São Luís', -23.67893, -46.74123, [
      ('Parque de Jardim São Luís', -23.65108, -46.75056, 4),
      ('Avenida principal de Jardim São Luís', -23.72293, -46.73143, 3),
      ('Terminal de ônibus de Jardim São Luís', -23.68504, -46.73296, 4),
      ('Mercado de Jardim São Luís', -23.65990, -46.72543, 4),
  ]),
  (2715906, 'Jardim Ângela', -23.71726, -46.76984, [
      ('Feira livre de Jardim Ângela', -23.69261, -46.76271, 2),
      ('Praça central de Jardim Ângela', -23.75289, -46.77232, 2),
      ('Mercado de Jardim Ângela', -23.73306, -46.73119, 2),
      ('Avenida principal de Jardim Ângela', -23.71733, -46.79491, 2),
  ]),
  (3049356, 'Jaçanã', -23.46306, -46.57563, [
      ('Terminal de ônibus de Jaçanã', -23.46821, -46.57810, 6),
      ('Praça central de Jaçanã', -23.43895, -46.56770, 4),
  ]),
  (3049503, 'José Bonifácio', -23.56821, -46.43328, [
      ('Avenida principal de José Bonifácio', -23.57595, -46.42675, 2),
      ('Praça central de José Bonifácio', -23.53882, -46.43370, 2),
      ('Terminal de ônibus de José Bonifácio', -23.55990, -46.44243, 3),
  ]),
  (3049504, 'Lajeado', -23.53441, -46.41003, [
      ('Feira livre de Lajeado', -23.53774, -46.40042, 2),
      ('Avenida principal de Lajeado', -23.52621, -46.42948, 2),
      ('Terminal de ônibus de Lajeado', -23.52404, -46.38828, 2),
  ]),
  (3049357, 'Lapa', -23.52183, -46.70513, [
      ('Largo da Lapa', -23.52200, -46.70400, 7),
      ('Terminal Lapa', -23.52230, -46.70200, 7),
      ('Feira livre de Lapa', -23.51354, -46.72168, 7),
  ]),
  (2731077, 'Liberdade', -23.56704, -46.63133, [
      ('Parque de Liberdade', -23.57107, -46.63072, 7),
      ('Mercado de Liberdade', -23.55894, -46.63538, 8),
  ]),
  (3049358, 'Limão', -23.49617, -46.67523, [
      ('Avenida principal de Limão', -23.49798, -46.67959, 7),
      ('Terminal de ônibus de Limão', -23.48483, -46.66655, 6),
  ]),
  (3049359, 'Mandaqui', -23.45878, -46.64153, [
      ('Mercado de Mandaqui', -23.43782, -46.63633, 5),
      ('Feira livre de Mandaqui', -23.48478, -46.64872, 6),
      ('Parque de Mandaqui', -23.46341, -46.63223, 7),
  ]),
  (2715907, 'Marsilac', -23.93509, -46.70775, [
      ('Feira livre de Marsilac', -23.95705, -46.63780, 2),
      ('Parque de Marsilac', -23.91057, -46.80790, 2),
      ('Avenida principal de Marsilac', -23.98919, -46.74539, 2),
      ('Terminal de ônibus de Marsilac', -23.88926, -46.70879, 2),
  ]),
  (1706557, 'Moema', -23.59693, -46.66164, [
      ('Parque Ibirapuera', -23.58740, -46.65760, 9),
      ('Mercado de Moema', -23.61315, -46.66532, 6),
      ('Parque de Moema', -23.59778, -46.67106, 7),
  ]),
  (3049448, 'Mooca', -23.56091, -46.59631, [
      ('Estação Mooca', -23.55860, -46.59970, 6),
      ('Rua da Mooca', -23.56000, -46.59900, 6),
  ]),
  (3049162, 'Morumbi', -23.59515, -46.70913, [
      ('Praça central de Morumbi', -23.60255, -46.70882, 6),
      ('Parque de Morumbi', -23.57644, -46.70139, 6),
      ('Mercado de Morumbi', -23.58783, -46.72018, 5),
  ]),
  (2715908, 'Parelheiros', -23.83122, -46.71774, [
      ('Praça central de Parelheiros', -23.81687, -46.73312, 2),
      ('Avenida principal de Parelheiros', -23.90312, -46.61559, 2),
      ('Mercado de Parelheiros', -23.74609, -46.76045, 2),
      ('Terminal de ônibus de Parelheiros', -23.88031, -46.69073, 2),
  ]),
  (2731078, 'Pari', -23.52698, -46.61747, [
      ('Avenida principal de Pari', -23.52978, -46.61797, 8),
      ('Parque de Pari', -23.52644, -46.60848, 7),
  ]),
  (3049505, 'Parque do Carmo', -23.57542, -46.46329, [
      ('Parque do Carmo', -23.57930, -46.46400, 5),
      ('Parque de Parque do Carmo', -23.55487, -46.46162, 3),
      ('Avenida principal de Parque do Carmo', -23.58352, -46.48720, 4),
  ]),
  (1692135, 'Pedreira', -23.70585, -46.64993, [
      ('Parque de Pedreira', -23.70790, -46.66505, 3),
      ('Feira livre de Pedreira', -23.71030, -46.62123, 2),
      ('Praça central de Pedreira', -23.72512, -46.64480, 2),
  ]),
  (3049506, 'Penha', -23.52261, -46.53086, [
      ('Largo do Rosário da Penha', -23.52800, -46.54400, 6),
      ('Praça central de Penha', -23.53060, -46.49191, 4),
      ('Feira livre de Penha', -23.52100, -46.51775, 5),
  ]),
  (3049360, 'Perdizes', -23.53916, -46.68061, [
      ('Parque de Perdizes', -23.53142, -46.68224, 7),
      ('Terminal de ônibus de Perdizes', -23.54740, -46.67522, 7),
  ]),
  (3049361, 'Perus', -23.40697, -46.74805, [
      ('Praça central de Perus', -23.40819, -46.76681, 3),
      ('Avenida principal de Perus', -23.41754, -46.71139, 5),
      ('Parque de Perus', -23.39211, -46.73663, 2),
  ]),
  (3049362, 'Pinheiros', -23.56611, -46.68914, [
      ('Largo da Batata', -23.56620, -46.69130, 9),
      ('Praça Benedito Calixto', -23.56300, -46.68360, 7),
      ('Av. Faria Lima', -23.57000, -46.69300, 8),
  ]),
  (3049449, 'Pirituba', -23.47989, -46.72676, [
      ('Mercado de Pirituba', -23.46652, -46.73024, 3),
      ('Praça central de Pirituba', -23.50502, -46.71073, 5),
      ('Avenida principal de Pirituba', -23.48195, -46.74956, 5),
  ]),
  (3049507, 'Ponte Rasa', -23.51602, -46.49186, [
      ('Parque de Ponte Rasa', -23.51969, -46.48820, 4),
      ('Mercado de Ponte Rasa', -23.51518, -46.51349, 5),
  ]),
  (3049164, 'Raposo Tavares', -23.59235, -46.78570, [
      ('Avenida principal de Raposo Tavares', -23.58674, -46.78473, 5),
      ('Feira livre de Raposo Tavares', -23.59014, -46.75781, 5),
      ('Mercado de Raposo Tavares', -23.60478, -46.80326, 4),
  ]),
  (2731079, 'República', -23.54410, -46.64103, [
      ('Feira livre de República', -23.54295, -46.64119, 8),
      ('Avenida principal de República', -23.55300, -46.63943, 8),
  ]),
  (3049165, 'Rio Pequeno', -23.57096, -46.75858, [
      ('Avenida principal de Rio Pequeno', -23.57201, -46.76625, 4),
      ('Parque de Rio Pequeno', -23.57365, -46.74172, 5),
      ('Mercado de Rio Pequeno', -23.55770, -46.75329, 4),
  ]),
  (2162062, 'Sacomã', -23.63063, -46.59779, [
      ('Mercado de Sacomã', -23.61177, -46.59836, 7),
      ('Feira livre de Sacomã', -23.65529, -46.60972, 4),
      ('Avenida principal de Sacomã', -23.63743, -46.58722, 4),
  ]),
  (2731080, 'Santa Cecília', -23.53315, -46.65297, [
      ('Praça central de Santa Cecília', -23.52816, -46.65733, 7),
      ('Mercado de Santa Cecília', -23.53466, -46.64274, 8),
  ]),
  (3049363, 'Santana', -23.50145, -46.63121, [
      ('Terminal Santana', -23.49900, -46.62500, 7),
      ('Rua Voluntários da Pátria', -23.50500, -46.62800, 6),
      ('Parque de Santana', -23.49045, -46.64531, 6),
  ]),
  (1692136, 'Santo Amaro', -23.64218, -46.70163, [
      ('Terminal Santo Amaro', -23.65600, -46.71000, 8),
      ('Largo Treze de Maio', -23.65370, -46.70900, 7),
      ('Avenida principal de Santo Amaro', -23.64324, -46.67686, 5),
  ]),
  (3049450, 'Sapopemba', -23.60492, -46.51057, [
      ('Mercado de Sapopemba', -23.61421, -46.49440, 4),
      ('Terminal de ônibus de Sapopemba', -23.58817, -46.52963, 6),
      ('Praça central de Sapopemba', -23.61133, -46.52129, 5),
  ]),
  (1710682, 'Saúde', -23.61351, -46.64150, [
      ('Feira livre de Saúde', -23.61790, -46.65397, 6),
      ('Terminal de ônibus de Saúde', -23.60374, -46.63074, 8),
      ('Parque de Saúde', -23.62494, -46.63184, 7),
  ]),
  (3032218, 'Socorro', -23.68597, -46.71393, [
      ('Avenida principal de Socorro', -23.67581, -46.70964, 4),
      ('Feira livre de Socorro', -23.70671, -46.71759, 3),
      ('Praça central de Socorro', -23.69389, -46.70182, 4),
  ]),
  (3049451, 'São Domingos', -23.49421, -46.74631, [
      ('Parque de São Domingos', -23.49255, -46.74992, 4),
      ('Avenida principal de São Domingos', -23.51069, -46.72415, 6),
      ('Terminal de ônibus de São Domingos', -23.47822, -46.76635, 4),
  ]),
  (3049452, 'São Lucas', -23.59453, -46.54276, [
      ('Feira livre de São Lucas', -23.59928, -46.54445, 6),
      ('Terminal de ônibus de São Lucas', -23.57978, -46.55447, 6),
      ('Praça central de São Lucas', -23.61118, -46.52802, 6),
  ]),
  (3049453, 'São Mateus', -23.59996, -46.47973, [
      ('Mercado de São Mateus', -23.60589, -46.48066, 4),
      ('Praça central de São Mateus', -23.58279, -46.50109, 4),
      ('Parque de São Mateus', -23.60936, -46.45880, 3),
  ]),
  (3049454, 'São Miguel', -23.50040, -46.44167, [
      ('Praça central de São Miguel', -23.49787, -46.44555, 2),
      ('Terminal de ônibus de São Miguel', -23.52273, -46.43356, 2),
      ('Feira livre de São Miguel', -23.48231, -46.44376, 3),
  ]),
  (3049364, 'São Rafael', -23.62844, -46.45247, [
      ('Praça central de São Rafael', -23.62115, -46.44449, 2),
      ('Feira livre de São Rafael', -23.62371, -46.47702, 4),
      ('Terminal de ônibus de São Rafael', -23.63893, -46.45870, 2),
  ]),
  (2731081, 'Sé', -23.54786, -46.63153, [
      ('Praça da Sé', -23.55050, -46.63330, 10),
      ('Mercado Municipal', -23.54160, -46.62970, 9),
      ('Rua 25 de Março', -23.54400, -46.63100, 10),
      ('Parque Dom Pedro II', -23.54300, -46.62800, 7),
  ]),
  (3049455, 'Tatuapé', -23.53827, -46.56762, [
      ('Parque de Tatuapé', -23.54942, -46.57342, 7),
      ('Mercado de Tatuapé', -23.52612, -46.55858, 6),
      ('Avenida principal de Tatuapé', -23.53005, -46.58114, 6),
  ]),
  (3049365, 'Tremembé', -23.41558, -46.59043, [
      ('Terminal de ônibus de Tremembé', -23.37345, -46.55254, 3),
      ('Feira livre de Tremembé', -23.45713, -46.63039, 6),
      ('Praça central de Tremembé', -23.43611, -46.57188, 4),
      ('Avenida principal de Tremembé', -23.39635, -46.59689, 2),
  ]),
  (3049366, 'Tucuruvi', -23.47648, -46.60519, [
      ('Mercado de Tucuruvi', -23.47641, -46.59628, 7),
      ('Feira livre de Tucuruvi', -23.46906, -46.62640, 6),
      ('Terminal de ônibus de Tucuruvi', -23.49020, -46.60764, 6),
  ]),
  (2165529, 'Vila Andrade', -23.62539, -46.72834, [
      ('Mercado de Vila Andrade', -23.63119, -46.72575, 4),
      ('Avenida principal de Vila Andrade', -23.61837, -46.74604, 5),
      ('Praça central de Vila Andrade', -23.61978, -46.70830, 5),
  ]),
  (3049456, 'Vila Curuçá', -23.50984, -46.41552, [
      ('Mercado de Vila Curuçá', -23.51011, -46.42603, 3),
      ('Praça central de Vila Curuçá', -23.52415, -46.40002, 2),
      ('Parque de Vila Curuçá', -23.49688, -46.40956, 2),
  ]),
  (3049457, 'Vila Formosa', -23.56816, -46.54595, [
      ('Parque de Vila Formosa', -23.56558, -46.54345, 5),
      ('Feira livre de Vila Formosa', -23.55553, -46.56651, 6),
  ]),
  (3049367, 'Vila Guilherme', -23.50955, -46.60704, [
      ('Avenida principal de Vila Guilherme', -23.51588, -46.61695, 7),
      ('Parque de Vila Guilherme', -23.49523, -46.60143, 6),
  ]),
  (3049458, 'Vila Jacuí', -23.50244, -46.46225, [
      ('Parque de Vila Jacuí', -23.50878, -46.45133, 3),
      ('Mercado de Vila Jacuí', -23.48513, -46.46426, 4),
      ('Feira livre de Vila Jacuí', -23.51595, -46.47395, 5),
  ]),
  (3049368, 'Vila Leopoldina', -23.52995, -46.73462, [
      ('Feira livre de Vila Leopoldina', -23.53677, -46.73537, 6),
      ('Praça central de Vila Leopoldina', -23.51881, -46.72804, 5),
  ]),
  (3049369, 'Vila Maria', -23.51273, -46.57870, [
      ('Avenida principal de Vila Maria', -23.52125, -46.59106, 8),
      ('Feira livre de Vila Maria', -23.51055, -46.55842, 6),
      ('Terminal de ônibus de Vila Maria', -23.49844, -46.58268, 7),
  ]),
  (3049370, 'Vila Mariana', -23.58673, -46.63568, [
      ('Metrô Vila Mariana', -23.58900, -46.63400, 6),
      ('Praça central de Vila Mariana', -23.57062, -46.64916, 8),
      ('Avenida principal de Vila Mariana', -23.58137, -46.61868, 7),
  ]),
  (3049508, 'Vila Matilde', -23.53983, -46.51684, [
      ('Terminal de ônibus de Vila Matilde', -23.54077, -46.52280, 6),
      ('Avenida principal de Vila Matilde', -23.54086, -46.49951, 5),
      ('Parque de Vila Matilde', -23.53613, -46.54370, 6),
  ]),
  (3049371, 'Vila Medeiros', -23.48901, -46.57767, [
      ('Terminal de ônibus de Vila Medeiros', -23.49543, -46.56714, 5),
      ('Avenida principal de Vila Medeiros', -23.49254, -46.59487, 6),
  ]),
  (3049459, 'Vila Prudente', -23.59316, -46.57309, [
      ('Avenida principal de Vila Prudente', -23.59382, -46.57919, 5),
      ('Feira livre de Vila Prudente', -23.60735, -46.55427, 6),
      ('Praça central de Vila Prudente', -23.57647, -46.58083, 6),
  ]),
  (3049170, 'Vila Sônia', -23.59899, -46.73907, [
      ('Praça central de Vila Sônia', -23.59397, -46.72709, 5),
      ('Avenida principal de Vila Sônia', -23.59567, -46.75691, 5),
      ('Mercado de Vila Sônia', -23.61400, -46.73765, 6),
  ]),
  (3049460, 'Água Rasa', -23.56658, -46.57187, [
      ('Feira livre de Água Rasa', -23.55837, -46.57220, 7),
      ('Praça central de Água Rasa', -23.57809, -46.56108, 7),
  ]),
];
