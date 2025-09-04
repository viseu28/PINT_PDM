const Sequelize = require('sequelize');
module.exports = function (sequelize, DataTypes) {
  return sequelize.define('areas', {
    idarea: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    idcategoria: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    nome: {
      type: DataTypes.TEXT,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'areas',
    schema: 'public',
    timestamps: false
  });
};
