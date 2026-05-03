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

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review all test results and investigate any failures before proceeding.

## 4. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **`System.Data`** and ADO.NET-related types, since this project appears to be ADO-focused (`AdoCore`). Verify that database provider packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, etc.) are explicitly referenced and up to date.
- Any use of `System.Configuration.ConfigurationManager` — this requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- `DataSet` and `DataTable` serialization behavior differences.

## 5. Verify NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm it targets `.NET Standard 2.0` or later, or has a specific `net6.0`/`net8.0` compatible version. You can check compatibility at [nuget.org](https://www.nuget.org).

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 6. Test on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues such as:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Platform-specific native dependencies

## 7. Review Runtime Configuration

Check that `appsettings.json` or any other configuration files are present and correctly structured. If the project previously relied on `App.config` or `Web.config`, ensure those settings have been migrated to the appropriate .NET configuration system.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. For a self-contained deployment, add:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (`linux-x64`, `osx-x64`, etc.) as needed.