const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('formCurriculo', {
    idcurriculo: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    ficheirocurriculo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    datahora: {
      type: DataTypes.DATE,
      allowNull: true
    }
  }, {
    sequelize,
    tableName: 'form_curriculo',
    schema: 'public',
    timestamps: false
  });
};
