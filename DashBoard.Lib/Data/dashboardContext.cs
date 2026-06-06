using DashBoard.Lib.DTOs;
using DashBoard.Lib.Models;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;

namespace DashBoard.Lib.Data;

public partial class dashboardContext : IdentityDbContext<ApplicationUser>
{
    public dashboardContext()
    {
    }

    public dashboardContext(DbContextOptions<dashboardContext> options)
        : base(options)
    {
    }
    public async Task SafeAddAsync<T>(T entity) where T : class
    {
        await Set<T>().AddAsync(entity);

        try
        {
            await SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            
            Entry(entity).State = EntityState.Detached;
            await Set<T>().AddAsync(entity);
            await SaveChangesAsync();
        }
    }
    public virtual DbSet<UserEvent> UserEvents { get; set; }
    
    public virtual DbSet<address> addresses { get; set; }

    public virtual DbSet<article> articles { get; set; }

    public virtual DbSet<district> districts { get; set; }
    public virtual DbSet<EventLog> EventLogs { get; set; }

    public virtual DbSet<employee> employees { get; set; }

    public virtual DbSet<objects_for_apartmen> objects_for_apartmens { get; set; }

    public virtual DbSet<overfly_block1> overfly_block1s { get; set; }

    public virtual DbSet<overfly_block2> overfly_block2s { get; set; }

    public virtual DbSet<photo> photos { get; set; }

    public virtual DbSet<robot> robots { get; set; }

    public virtual DbSet<robots_analitic> robots_analitics { get; set; }

    public virtual DbSet<robots_apartament> robots_apartaments { get; set; }

    public virtual DbSet<sourse> sourses { get; set; }

    public virtual DbSet<statusapplication> statusapplications { get; set; }

    public virtual DbSet<type_photo> type_photos { get; set; }

    public virtual DbSet<violation> violations { get; set; }

    public virtual DbSet<work_progress> work_progresses { get; set; }

    public virtual DbSet<work_progress_violation> work_progress_violations { get; set; }
    public virtual DbSet<ChatMessageEntity> ChatMessages { get; set; }
    public DbSet<ApplicationDKN> ApplicationDKN { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.Entity<AddWorkProgressResult>().HasNoKey();
        modelBuilder.Entity<JsonResultDto>().HasNoKey();
        modelBuilder.Entity<ApplicationDKN>().HasNoKey();
        modelBuilder.Entity<address>(entity =>
        {
            entity.HasKey(e => e.id).HasName("addresses_pkey");

            entity.Property(e => e.address1)
                .HasMaxLength(500)
                .HasColumnName("address");
        });

        modelBuilder.Entity<article>(entity =>
        {
            entity.HasKey(e => e.id).HasName("article_pkey");

            entity.ToTable("article");

            entity.Property(e => e.article1)
                .HasMaxLength(150)
                .HasColumnName("article");
        });

        modelBuilder.Entity<district>(entity =>
        {
            entity.HasKey(e => e.id).HasName("districts_pkey");

            entity.Property(e => e.name).HasMaxLength(200);
        });

        modelBuilder.Entity<employee>(entity =>
        {
            entity.HasKey(e => e.id).HasName("employee_pkey");

            entity.ToTable("employee");

            entity.Property(e => e.employee1)
                .HasMaxLength(200)
                .HasColumnName("employee");
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

            entity.Property(e => e.id).ValueGeneratedOnAdd();

            entity.HasOne(d => d.idNavigation).WithOne(p => p.overfly_block1)
                .HasForeignKey<overfly_block1>(d => d.id)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("overfly_block1_addresses_fk");

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

            entity.HasIndex(e => e.id_address, "fki_fk_address");

            entity.HasIndex(e => e.id_district, "fki_fk_district");

            entity.HasIndex(e => e.id_status, "fki_fk_status");

            entity.HasOne(d => d.id_addressNavigation).WithMany(p => p.overfly_block2s)
                .HasForeignKey(d => d.id_address)
                .HasConstraintName("fk_address");

            entity.HasOne(d => d.id_districtNavigation).WithMany(p => p.overfly_block2s)
                .HasForeignKey(d => d.id_district)
                .HasConstraintName("fk_district");

            entity.HasOne(d => d.id_statusNavigation).WithMany(p => p.overfly_block2s)
                .HasForeignKey(d => d.id_status)
                .HasConstraintName("fk_status");
        });

        modelBuilder.Entity<photo>(entity =>
        {
            entity.HasKey(e => e.id).HasName("bpla_pkey");

            entity.Property(e => e.id).HasDefaultValueSql("nextval('bpla_id_seq'::regclass)");

            entity.HasOne(d => d.id_typeNavigation).WithMany(p => p.Inverseid_typeNavigation)
                .HasForeignKey(d => d.id_type)
                .HasConstraintName("photos_photos_fk");
        });

        modelBuilder.Entity<robot>(entity =>
        {
            entity.HasKey(e => e.id).HasName("robots_pkey");

            entity.HasIndex(e => e.name, "indx_robot_name");

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

        modelBuilder.Entity<sourse>(entity =>
        {
            entity.HasKey(e => e.id).HasName("source_pkey");

            entity.ToTable("sourse");

            entity.Property(e => e.id).HasDefaultValueSql("nextval('source_id_seq'::regclass)");
            entity.Property(e => e.source).HasMaxLength(150);
        });

        modelBuilder.Entity<statusapplication>(entity =>
        {
            entity.HasKey(e => e.id).HasName("statusapplication_pkey");

            entity.ToTable("statusapplication");

            entity.Property(e => e.name).HasMaxLength(200);
        });

        modelBuilder.Entity<type_photo>(entity =>
        {
            entity.HasKey(e => e.id).HasName("type_photo_pkey");

            entity.ToTable("type_photo");

            entity.Property(e => e.name).HasMaxLength(10);
        });

        modelBuilder.Entity<violation>(entity =>
        {
            entity.HasKey(e => e.id).HasName("violations_pkey");

            entity.Property(e => e.name).HasMaxLength(200);
        });

        modelBuilder.Entity<work_progress>(entity =>
        {
            entity.HasKey(e => e.id).HasName("work_progress_pkey");
            entity.ToTable("work_progress");

            entity.Property(e => e.comment).HasMaxLength(500);
            entity.Property(e => e.created_at)
                .HasDefaultValueSql("CURRENT_TIMESTAMP")
                .HasColumnType("timestamp without time zone");
            entity.Property(e => e.created_by_user_id).HasMaxLength(450);

            entity.HasOne(d => d.id_sourseNavigation)
                .WithMany(p => p.work_progresses)
                .HasForeignKey(d => d.id_sourse)
                .HasConstraintName("work_progress_id_sourse_fkey");

            
            entity.HasOne(d => d.CreatedByUser)
                .WithMany()
                .HasForeignKey(d => d.created_by_user_id)
                .HasConstraintName("work_progress_created_by_fkey");
        });

        modelBuilder.Entity<work_progress_violation>(entity =>
        {
            entity.HasKey(e => e.id).HasName("work_progress_violations_pkey");

            entity.HasOne(d => d.id_work_progressNavigation).WithMany(p => p.work_progress_violations)
                .HasForeignKey(d => d.id_work_progress)
                .HasConstraintName("work_progress_violations_id_work_progress_fkey");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
