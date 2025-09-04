const Sequelize = require('sequelize');
module.exports = function (sequelize, DataTypes) {
  return sequelize.define('topicos', {
    idtopicos: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    idarea: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    nome: {
      type: DataTypes.TEXT,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'topicos',
    schema: 'public',
    timestamps: false
  });
};
