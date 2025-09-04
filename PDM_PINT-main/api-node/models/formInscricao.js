const Sequelize = require('sequelize');
module.exports = function (sequelize, DataTypes) {
  return sequelize.define('form_inscricao', {
    idinscricao: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
      allowNull: false
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    objetivos: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    data: {
      type: DataTypes.DATE,
      allowNull: false
    },
    nota: {
      type: DataTypes.FLOAT, // ou INTEGER, depende do tipo da coluna
      allowNull: true
    },
    estado: {
      type: DataTypes.BOOLEAN,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'form_inscricao',
    schema: 'public',
    timestamps: false
  });
};
