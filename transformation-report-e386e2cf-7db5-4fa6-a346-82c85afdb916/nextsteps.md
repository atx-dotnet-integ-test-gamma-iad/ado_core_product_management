# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-only TFM such as `net472` or `net48`, update it accordingly.

---

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate compatibility issues, particularly around deprecated APIs or platform-specific calls.

---

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the old .NET Framework and the new .NET runtime.

---

## 4. Check for Platform-Specific Code

Search the codebase for APIs that were Windows-specific under .NET Framework and may behave differently or throw `PlatformNotSupportedException` on Linux or macOS. Common areas to inspect include:

- `System.Drawing` (GDI+)
- `Microsoft.Win32.Registry`
- `System.Security.Permissions`
- COM interop or P/Invoke calls
- `AppDomain.CreateDomain`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where applicable.

---

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. Confirm each package supports your target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only support .NET Framework with their cross-platform equivalents.

---

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in .NET 5+.

---

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

---

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for Linux x64
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.