import { PieChart, Pie, Cell, Tooltip, Legend, Sector } from 'recharts';
import { useState } from 'react';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8', '#82ca9d', '#ffc658', '#a4de6c', '#d0ed57', '#83a6ed'];

const renderActiveShape = ({ cx, cy, innerRadius, outerRadius, startAngle, endAngle, fill, payload, percent }) => (
  <g>
    <text x={cx} y={cy - 20} textAnchor="middle" fill="white" fontSize={16} fontWeight={700}>{payload.name}</text>
    <text x={cx} y={cy + 5} textAnchor="middle" fill="#8EAEE3" fontSize={14}>{`${(percent * 100).toFixed(1)}%`}</text>
    <Sector cx={cx} cy={cy} innerRadius={innerRadius} outerRadius={outerRadius + 10} startAngle={startAngle} endAngle={endAngle} fill={fill}/>
  </g>
);

const CustomTooltip = ({ active, payload }) => {
  if (active && payload && payload.length) {
    return (
      <div style={{ backgroundColor: '#262E3B', border: 'none', borderRadius: 8, padding: '8px 12px' }}>
        <p style={{ color: 'white', margin: 0 }}>{`${payload[0].value.toLocaleString()} bytes`}</p>
      </div>
    );
  }
  return null;
};

function LanguagesDiagram({ languages }) {
  const [activeIndex, setActiveIndex] = useState(null);

  if (!languages?.length) {
    return <div style={{ color: 'white', textAlign: 'center', paddingTop: 50, fontSize: 18 }}>Нет данных о языках</div>;
  }

  const chartData = languages.map(lang => ({ name: lang.language, value: lang.bytes_count || 0 }));

  return (
    <div style={{ height: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center', backgroundColor: "#262E3B", borderRadius: 20, flexWrap: "wrap", alignContent: "center" , padding: 20}}>
        <span style={{color: "white", fontSize: 26, fontWeight: 600}}>Языки репозитория:</span>
      <PieChart width={600} height={600} >
        <Pie
          activeIndex={activeIndex}
          activeShape={renderActiveShape}
          data={chartData}
          cx="50%"
          cy="50%" 
          outerRadius={200}
          innerRadius={80}
          dataKey="value"
          paddingAngle={0}
          onMouseEnter={(_, i) => setActiveIndex(i)}
          onMouseLeave={() => setActiveIndex(null)}
          animationDuration={500}
        >
          {chartData.map((_, i) => (
            <Cell key={i} fill={COLORS[i % COLORS.length]} stroke={activeIndex === i ? '#fff' : 'none'} strokeWidth={2} />
          ))}
        </Pie>
        <Tooltip content={<CustomTooltip />} />
        <Legend 
          verticalAlign="bottom"
          height={60} 
          wrapperStyle={{ paddingTop: '-20px' }} 
          formatter={(v) => <span style={{ color: 'white' }}>{v}</span>}
        />
      </PieChart>
    </div>
  );
}

export default LanguagesDiagram;
