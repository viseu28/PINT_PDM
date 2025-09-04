const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  return sequelize.define('recebe', {
    idpost: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    idtopicos: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'recebe',
    schema: 'public',
    timestamps: false
  });
};
