# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at build time. Run the application and exercise its primary code paths:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay attention to:
- Database connectivity, as ADO.NET provider packages may differ between .NET Framework and modern .NET.
- Any calls to APIs that were removed or changed in modern .NET (e.g., `System.Data` behavior differences).
- Configuration loading, since `App.config` is not natively supported in modern .NET; `appsettings.json` or environment variables should be used instead.

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm that each package targets .NET Standard 2.0 or later, or has a specific .NET 6/7/8 compatible version. You can check compatibility on [NuGet.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update any outdated packages that have newer compatible versions.

## 6. Validate ADO.NET Provider References

Since the project name suggests ADO.NET usage (`AdoCore`), confirm the correct database provider package is referenced. For example:

- **SQL Server**: `Microsoft.Data.SqlClient`
- **SQLite**: `Microsoft.Data.Sqlite`
- **PostgreSQL**: `Npgsql`

Ensure you are not relying on `System.Data.SqlClient`, which is the legacy package and has limited support in modern .NET.

## 7. Review App.config Usage

If the original project used `App.config` for connection strings or application settings, migrate those values to `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=...;Database=...;"
  }
}
```

Then use `Microsoft.Extensions.Configuration` to read these values in code.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present before deploying to the target environment.