const Sequelize = require('sequelize');
module.exports = function(sequelize, DataTypes) {
  const Post = sequelize.define('post', {
    idpost: {
      autoIncrement: true,
      type: DataTypes.INTEGER,
      allowNull: false,
      primaryKey: true
    },
    idutilizador: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    idtopico: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    texto: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    titulo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    datahora: {
      type: DataTypes.DATE,
      allowNull: false
    },
    anexo: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    url: {
      type: DataTypes.TEXT,
      allowNull: false
    }
  }, {
    sequelize,
    tableName: 'post',
    schema: 'public',
    timestamps: false
  });

  Post.associate = function(models) {
    Post.belongsTo(models.utilizador, { foreignKey: 'idutilizador', as: 'utilizador' });
  };

  return Post;
};