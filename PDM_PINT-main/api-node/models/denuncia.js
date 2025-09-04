const Sequelize = require('sequelize');
module.exports = function (sequelize, DataTypes) {
  return sequelize.define('denuncia', {
    iddenuncia: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },

    idpost: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    motivo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    data: {
      type: DataTypes.DATE,
      allowNull: false
    },
    idcomentario: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'denuncia',
    schema: 'public',
    timestamps: false
  });
};