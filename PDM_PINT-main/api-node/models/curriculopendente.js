const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('curriculopendente', {
    idcurriculopendente: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    curriculo: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'curriculopendente',
    schema: 'public',
    timestamps: false
  });
};
