# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Runtime Compatibility Issues

Some APIs that compiled successfully may behave differently or throw at runtime on cross-platform .NET. Pay particular attention to:

- **`System.Data`** and ADO.NET providers: Verify that any database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are the correct NuGet packages for cross-platform use.
- **`System.Configuration`**: If the project previously used `ConfigurationManager`, ensure the `System.Configuration.ConfigurationManager` NuGet package is referenced and that configuration files are correctly structured.
- **Platform-specific APIs**: Any use of Windows Registry, COM interop, or `System.Drawing` (GDI+) should be reviewed for cross-platform compatibility.

## 5. Review NuGet Package Versions

Open the `.csproj` file and review all `<PackageReference>` entries. Ensure:

- No packages are pinned to versions that only support .NET Framework.
- Packages have been updated to their latest stable versions compatible with your target framework.

You can check for outdated packages using:

```bash
dotnet list package --outdated
```

## 6. Validate Configuration Files

- Confirm that `app.config` or `web.config` files have been replaced or supplemented with `appsettings.json` where appropriate.
- If connection strings or application settings were previously stored in `app.config`, migrate them to `appsettings.json` and use `Microsoft.Extensions.Configuration` to access them.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

**Framework-dependent publish:**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained publish (includes the runtime):**
```bash
dotnet publish -c Release -f net8.0 --self-contained true -r linux-x64
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target.