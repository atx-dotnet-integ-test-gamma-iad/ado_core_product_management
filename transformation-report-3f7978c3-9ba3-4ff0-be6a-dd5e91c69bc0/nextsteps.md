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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **File path separators**: Replace hardcoded backslashes (`\`) with `Path.Combine` or `Path.DirectorySeparatorChar`.
- **Registry access**: `Microsoft.Win32.Registry` is Windows-only. If the code uses the registry, add a Windows runtime check or refactor the logic.
- **Windows-specific APIs**: Review any P/Invoke calls or references to `System.Windows.Forms` or `System.Drawing` which may require the `-windows` TFM suffix (e.g., `net8.0-windows`).
- **`AppDomain`**: Some `AppDomain` members are not supported in .NET Core and later. Check for `AppDomain.CreateDomain` or similar calls.
- **`BinaryFormatter`**: This is disabled by default in .NET 5+. If serialization is used, migrate to a supported alternative such as `System.Text.Json` or `System.Xml.Serialization`.

## 5. Review NuGet Package Versions

Open the `.csproj` file and check that all referenced NuGet packages have versions compatible with your target framework. Run the following to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, verifying that updated versions do not introduce breaking changes.

## 6. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in cross-platform .NET.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues not caught during the build.

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime <RID> --output ./publish
```

Replace `<RID>` with the appropriate Runtime Identifier, such as `win-x64`, `linux-x64`, or `osx-x64`.

Verify the contents of the `./publish` directory and confirm the application starts and behaves correctly in the target environment.