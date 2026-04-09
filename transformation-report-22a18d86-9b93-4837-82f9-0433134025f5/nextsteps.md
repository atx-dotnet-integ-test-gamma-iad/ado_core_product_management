# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even though they do not block compilation.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address the underlying logic or compatibility issues before proceeding.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET compared to .NET Framework. Pay attention to the following areas:

- **File paths**: Ensure no hardcoded Windows-style paths (backslashes) exist. Use `Path.Combine` or `Path.DirectorySeparatorChar` where appropriate.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the code uses the registry, it will need to be replaced with a cross-platform alternative such as configuration files or environment variables.
- **Windows-only APIs**: Review any P/Invoke calls or references to `System.Windows.Forms` or `System.Drawing` that may not be supported cross-platform without additional packages (e.g., `System.Drawing.Common` has platform restrictions as of .NET 6+).
- **Thread culture and encoding**: Verify that any culture-sensitive or encoding-sensitive operations behave as expected on the target platform.

## 5. Review NuGet Package Compatibility

Check that all NuGet packages referenced in `AdoCore.csproj` are compatible with the target framework. You can use the following command to inspect outdated or potentially incompatible packages:

```bash
dotnet list package --outdated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <TargetVersion>
```

## 6. Validate ADO-Specific Functionality

Since the project is named `AdoCore`, it likely contains data access logic. Verify the following:

- The `System.Data` and any database driver packages (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are referencing their cross-platform compatible versions.
- Connection strings are being read from a configuration source (e.g., `appsettings.json`) rather than being hardcoded or read from `ConfigurationManager` in a way that depends on `app.config`. Note that `System.Configuration.ConfigurationManager` is available as a NuGet package for .NET but reading from `app.config` may require additional setup.
- Any `DataSet`, `DataTable`, or `DataAdapter` usage still functions as expected, as these are supported but some edge-case behaviors may differ.

## 7. Test on Target Platform

If the goal is cross-platform execution, run the application on the intended non-Windows platform (Linux or macOS) to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# For a self-contained Linux x64 deployment
dotnet publish --configuration Release --runtime linux-x64 --self-contained true

# For a framework-dependent deployment
dotnet publish --configuration Release
```

The output will be placed in the `bin/Release/<TargetFramework>/publish/` directory by default.