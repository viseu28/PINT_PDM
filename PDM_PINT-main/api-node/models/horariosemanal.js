const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('horariosemanal', {
    idpercurso3: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idcurso: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    datainicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    horainicio: {
      type: DataTypes.DATE,
      allowNull: false
    },
    horafim: {
      type: DataTypes.DATE,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'horariosemanal',
    schema: 'public',
    timestamps: false
  });
};
