const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('horariopessoal', {
    idhorariop: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    datainicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    horarioinicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    horariofim: {
      type: DataTypes.DATE,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'horariopessoal',
    schema: 'public',
    timestamps: false
  });
};
