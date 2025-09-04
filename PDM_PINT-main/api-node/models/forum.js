const Sequelize = require('sequelize');
module.exports = function (sequelize, DataTypes) {
  return sequelize.define('forum', {
    idforum: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    idtopico: {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: {
        model: 'topicos',
        key: 'idtopicos'
      }
    },
    nome: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    descricao: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    datahora: {
      type: DataTypes.DATE,
      allowNull: false
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'forum',
    schema: 'public',
    timestamps: false
  });
};
