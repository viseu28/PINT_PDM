const Sequelize = require('sequelize');

module.exports = function(sequelize, DataTypes) {
  return sequelize.define('notificacao', {
    idnotificacao: {
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true,           // <- ESSENCIAL!
      autoIncrement: true         // <- opcional, mas comum se for chave primária
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    descricao: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    datahora: {
      type: DataTypes.DATE,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'notificacao',
    schema: 'public',
    timestamps: false
  });
};
