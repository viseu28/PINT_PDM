const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('material', {
    idconteudo: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    titulo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    descricaoc: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    },
    tipo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    idmaterial: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'material',
    schema: 'public',
    timestamps: false
  });
};
