using System;
using System.Collections.Generic;
using DashBoard.Lib.Models;
using Microsoft.EntityFrameworkCore;

namespace DashBoard.Lib.Data;

public partial class dashboardContext : DbContext
{
    public dashboardContext()
    {
    }

    public dashboardContext(DbContextOptions<dashboardContext> options)
        : base(options)
    {
    }

    public virtual DbSet<address> addresses { get; set; }

    public virtual DbSet<bpla> bplas { get; set; }

    public virtual DbSet<detector> detectors { get; set; }

    public virtual DbSet<district> districts { get; set; }

    public virtual DbSet<objects_for_apartmen> objects_for_apartmens { get; set; }

    public virtual DbSet<overfly_block1> overfly_block1s { get; set; }

    public virtual DbSet<overfly_block2> overfly_block2s { get; set; }

    public virtual DbSet<responsible> responsibles { get; set; }

    public virtual DbSet<robot> robots { get; set; }

    public virtual DbSet<robots_analitic> robots_analitics { get; set; }

    public virtual DbSet<robots_apartament> robots_apartaments { get; set; }

    public virtual DbSet<source> sources { get; set; }

    public virtual DbSet<statusapplication> statusapplications { get; set; }

    public virtual DbSet<violation> violations { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseNpgsql("Host=localhost;Port=5432;Database=dashboard;Username=postgres;Password=1111");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<address>(entity =>
        {
            entity.HasKey(e => e.id).HasName("addresses_pkey");

            entity.Property(e => e.address1).HasColumnName("address");
        });

        modelBuilder.Entity<bpla>(entity =>
        {
            entity.HasKey(e => e.id).HasName("bpla_pkey");

            entity.ToTable("bpla");

            entity.Property(e => e._double).HasColumnName("double");
            entity.Property(e => e.comment).HasMaxLength(500);

            entity.HasOne(d => d.detector).WithMany(p => p.bplas)
                .HasForeignKey(d => d.detector_id)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("bpla_detector_id_fkey");

            entity.HasOne(d => d.sourse).WithMany(p => p.bplas)
                .HasForeignKey(d => d.sourse_id)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("bpla_sourse_id_fkey");
        });

        modelBuilder.Entity<detector>(entity =>
        {
            entity.HasKey(e => e.id).HasName("detector_pkey");

            entity.ToTable("detector");

            entity.Property(e => e.name).HasMaxLength(30);
        });

        modelBuilder.Entity<district>(entity =>
        {
            entity.HasKey(e => e.id).HasName("districts_pkey");

            entity.Property(e => e.name).HasMaxLength(200);
        });

        modelBuilder.Entity<objects_for_apartmen>(entity =>
        {
            entity.HasKey(e => e.id).HasName("objects_for_apartmens_pkey");

            entity.Property(e => e.name).HasMaxLength(50);
        });

        modelBuilder.Entity<overfly_block1>(entity =>
        {
            entity.HasKey(e => e.id).HasName("overfly_block1_pkey");

            entity.ToTable("overfly_block1");

            entity.HasOne(d => d.idadressNavigation).WithMany(p => p.overfly_block1s)
                .HasForeignKey(d => d.idadress)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("fk_adress");

            entity.HasOne(d => d.iddistricNavigation).WithMany(p => p.overfly_block1s)
                .HasForeignKey(d => d.iddistric)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("fk_distric");

            entity.HasOne(d => d.idviolationNavigation).WithMany(p => p.overfly_block1s)
                .HasForeignKey(d => d.idviolation)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("fk_violation");
        });

        modelBuilder.Entity<overfly_block2>(entity =>
        {
            entity.HasKey(e => e.id).HasName("overfly_block2_pkey");

            entity.ToTable("overfly_block2");

            entity.HasOne(d => d.id_adressNavigation).WithMany(p => p.overfly_block2s)
                .HasForeignKey(d => d.id_adress)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("fk_adress2");

            entity.HasOne(d => d.id_districNavigation).WithMany(p => p.overfly_block2s)
                .HasForeignKey(d => d.id_distric)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("fk_distric2");
        });

        modelBuilder.Entity<responsible>(entity =>
        {
            entity.HasKey(e => e.id).HasName("responsible_pkey");

            entity.ToTable("responsible");

            entity.Property(e => e.name).HasMaxLength(50);
        });

        modelBuilder.Entity<robot>(entity =>
        {
            entity.HasKey(e => e.id).HasName("robots_pkey");

            entity.Property(e => e.name).HasMaxLength(70);
            entity.Property(e => e.short_name).HasMaxLength(20);
        });

        modelBuilder.Entity<robots_analitic>(entity =>
        {
            entity.HasKey(e => e.id).HasName("robots_analitic_pkey");

            entity.ToTable("robots_analitic");

            entity.Property(e => e.data_analize).HasColumnType("jsonb");

            entity.HasOne(d => d.idrobotsNavigation).WithMany(p => p.robots_analitics)
                .HasForeignKey(d => d.idrobots)
                .HasConstraintName("fk_robotsanalityc_robot");
        });

        modelBuilder.Entity<robots_apartament>(entity =>
        {
            entity.HasKey(e => e.id).HasName("robots_apartaments_pkey");

            entity.Property(e => e.comment).HasMaxLength(500);

            entity.HasOne(d => d._object).WithMany(p => p.robots_apartaments)
                .HasForeignKey(d => d.object_id)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("robots_apartaments_object_id_fkey");
        });

        modelBuilder.Entity<source>(entity =>
        {
            entity.HasKey(e => e.id).HasName("source_pkey");

            entity.ToTable("source");

            entity.Property(e => e.name).HasMaxLength(30);
        });

        modelBuilder.Entity<statusapplication>(entity =>
        {
            entity.HasKey(e => e.id).HasName("statusapplication_pkey");

            entity.ToTable("statusapplication");

            entity.Property(e => e.name).HasMaxLength(200);
        });

        modelBuilder.Entity<violation>(entity =>
        {
            entity.HasKey(e => e.id).HasName("violations_pkey");

            entity.Property(e => e.name).HasMaxLength(200);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
